-- =====================================================================
--  PG Rent App  |  001_core_schema.sql
--  PostgreSQL 15+ (built for Supabase). Apply through the migration tool,
--  never by clicking around in the dashboard.
-- ---------------------------------------------------------------------
--  RULES THIS FILE FOLLOWS
--   1. Normalised (3NF / BCNF): every fact lives in exactly one place.
--      Lists go in child tables (no comma lists, no phone1/phone2),
--      repeated labels go in lookup tables, many-to-many uses a junction.
--   2. Money is integer paise (bigint), never float. Show it as rupees in
--      the app only.
--   3. History is kept. Nothing important is deleted or overwritten:
--      rows get a status, an end date or a void flag, and every change is
--      copied into audit_log.
--   4. Balances are never stored. Views calculate them from charges and
--      payments, so they cannot drift out of sync.
--   5. Modules only point "upwards" (a module may reference only modules
--      listed before it), so one module can be changed or replaced
--      without touching the others.
--
--  MODULES
--   M0 reference   roles, payment_methods, charge_types, room_types, amenities,
--                  document_types, relationship_types, upi_apps,
--                  states, cities, addresses
--   M1 people      persons, files, emergency_contacts, person_documents
--   M2 pg          pgs, pg_members, pg_billing_settings, pg_payment_accounts, reminder_rules
--   M3 inventory   rooms, room_amenities, beds
--   M4 stays       stays, stay_bed_assignments, stay_rent_terms
--   M5 billing     charges, payments, payment_upi_details,
--                  payment_allocations, receipts
--   M6 comms       device_tokens, notifications
--   M7 platform    audit_log
--  Later modules (complaints, announcements, consent + reliability score)
--  are NEW tables that point at persons / pgs / stays. Nothing here changes.
--
--  HOW TO CHANGE THINGS SAFELY
--   * New field        -> add a nullable column (or a default), in a new migration.
--   * New choice       -> insert a row into the lookup table (no app release needed).
--   * New payment kind -> add a row to payment_methods, and (if it needs extra
--                         fields) a new 1:1 table like payment_upi_details.
--   * Remove something -> two releases: stop using it, then drop it later.
--  Old app versions stay in people's phones, so never rename or drop what a
--  released app still reads.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. Small helpers
-- ---------------------------------------------------------------------
create or replace function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- "Today" in India, whatever timezone the database server runs in.
create or replace function today_ist() returns date
language sql stable as $$ select (now() at time zone 'Asia/Kolkata')::date $$;

-- "98765 43210", "+91 98765-43210", "098765 43210"  ->  +919876543210
-- Returns null when the number cannot be understood.
create or replace function normalize_phone(p text) returns text
language sql immutable as $$
  select case
    when d ~ '^[6-9][0-9]{9}$'   then '+91' || d
    when d ~ '^0[6-9][0-9]{9}$'  then '+91' || substr(d, 2)
    when d ~ '^91[6-9][0-9]{9}$' then '+' || d
    when p ~ '^\s*\+[1-9]'       then '+' || d
    else null
  end
  from (select regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g') as d) x
$$;


-- ---------------------------------------------------------------------
-- M0. Reference data (lookups). Add rows to extend; no app release needed.
-- ---------------------------------------------------------------------
create table roles (
  id    smallint generated always as identity primary key,
  code  text not null unique,
  label text not null
);

create table payment_methods (
  id        smallint generated always as identity primary key,
  code      text not null unique,
  label     text not null,
  is_active boolean not null default true
);

create table charge_types (
  id            smallint generated always as identity primary key,
  code          text not null unique,
  label         text not null,
  is_refundable boolean not null default false,
  is_recurring  boolean not null default false,
  is_active     boolean not null default true
);

create table room_types (
  id    smallint generated always as identity primary key,
  code  text not null unique,
  label text not null
);

create table amenities (
  id    smallint generated always as identity primary key,
  code  text not null unique,
  label text not null
);

create table document_types (
  id    smallint generated always as identity primary key,
  code  text not null unique,
  label text not null
);

create table relationship_types (
  id    smallint generated always as identity primary key,
  code  text not null unique,
  label text not null
);

create table upi_apps (
  id    smallint generated always as identity primary key,
  code  text not null unique,
  label text not null
);

insert into roles (code, label) values
  ('owner', 'Owner'), ('manager', 'Manager'), ('caretaker', 'Caretaker');

insert into payment_methods (code, label) values
  ('cash', 'Cash'), ('upi', 'UPI'), ('bank_transfer', 'Bank transfer'), ('cheque', 'Cheque');

insert into charge_types (code, label, is_refundable, is_recurring) values
  ('rent', 'Rent', false, true),
  ('security_deposit', 'Security deposit', true, false),
  ('electricity', 'Electricity', false, false),
  ('food', 'Food', false, false),
  ('laundry', 'Laundry', false, false),
  ('maintenance', 'Maintenance', false, false),
  ('late_fee', 'Late fee', false, false),
  ('other', 'Other', false, false);

insert into room_types (code, label) values
  ('single', 'Single'), ('double', '2 sharing'), ('triple', '3 sharing'), ('dormitory', 'Dormitory');

insert into amenities (code, label) values
  ('ac', 'AC'), ('attached_bathroom', 'Attached bathroom'), ('balcony', 'Balcony'),
  ('geyser', 'Geyser'), ('wifi', 'Wi-Fi'), ('cupboard', 'Cupboard');

insert into document_types (code, label) values
  ('aadhaar', 'Aadhaar'), ('pan', 'PAN'), ('driving_license', 'Driving licence'),
  ('passport', 'Passport'), ('college_id', 'College ID'), ('company_id', 'Company ID'),
  ('other', 'Other');

insert into relationship_types (code, label) values
  ('father', 'Father'), ('mother', 'Mother'), ('spouse', 'Spouse'), ('sibling', 'Sibling'),
  ('guardian', 'Guardian'), ('friend', 'Friend'), ('other', 'Other');

insert into upi_apps (code, label) values
  ('gpay', 'Google Pay'), ('phonepe', 'PhonePe'), ('paytm', 'Paytm'), ('bhim', 'BHIM'),
  ('amazon_pay', 'Amazon Pay'), ('cred', 'CRED'), ('other', 'Other app');

-- Geography: city depends on state (not on the address), so it has its own table.
-- Only a starter list is seeded here. Import the full list when needed.
create table states (
  id   smallint generated always as identity primary key,
  name text not null unique
);

create table cities (
  id       integer generated always as identity primary key,
  state_id smallint not null references states (id),
  name     text not null,
  unique (state_id, name)
);

create table addresses (
  id         uuid primary key default gen_random_uuid(),
  line1      text not null,
  line2      text,
  area       text,
  city_id    integer not null references cities (id),
  pincode    text check (pincode ~ '^[1-9][0-9]{5}$'),
  latitude   numeric(9, 6),
  longitude  numeric(9, 6),
  created_at timestamptz not null default now()
);

insert into states (name) values
  ('Karnataka'), ('Telangana'), ('Tamil Nadu'), ('Maharashtra'),
  ('Kerala'), ('Delhi'), ('Andhra Pradesh');

insert into cities (state_id, name)
select s.id, c.city
from (values
  ('Karnataka', 'Bengaluru'), ('Karnataka', 'Mysuru'), ('Karnataka', 'Mangaluru'),
  ('Karnataka', 'Hubballi'), ('Telangana', 'Hyderabad'), ('Tamil Nadu', 'Chennai'),
  ('Tamil Nadu', 'Coimbatore'), ('Maharashtra', 'Mumbai'), ('Maharashtra', 'Pune'),
  ('Kerala', 'Kochi'), ('Delhi', 'New Delhi'), ('Andhra Pradesh', 'Visakhapatnam')
) as c (state_name, city)
join states s on s.name = c.state_name;


-- ---------------------------------------------------------------------
-- M1. People and files
--  persons = one row per human, keyed by phone number. The row can exist
--  BEFORE the person ever logs in (an owner adds a guest by phone), and is
--  linked to the login (auth_user_id) on first sign-in.
-- ---------------------------------------------------------------------
create table persons (
  id            uuid primary key default gen_random_uuid(),
  auth_user_id  uuid unique references auth.users (id) on delete set null,
  phone         text not null unique check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  full_name     text,
  email         text,
  photo_file_id uuid,                       -- foreign key added below
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- One table describes every uploaded file (photos, ID proofs, screenshots,
-- receipt PDFs). Other tables just point at files.id.
create table files (
  id          uuid primary key default gen_random_uuid(),
  bucket      text not null,
  object_path text not null,
  mime_type   text,
  size_bytes  bigint check (size_bytes is null or size_bytes >= 0),
  uploaded_by uuid references persons (id),
  created_at  timestamptz not null default now(),
  unique (bucket, object_path)
);

alter table persons
  add constraint persons_photo_file_fk foreign key (photo_file_id) references files (id);

-- A person can have several emergency contacts (1NF: no contact1/contact2 columns).
create table emergency_contacts (
  id                   uuid primary key default gen_random_uuid(),
  person_id            uuid not null references persons (id),
  name                 text not null,
  phone                text not null check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  relationship_type_id smallint references relationship_types (id),
  is_primary           boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);
create unique index emergency_contacts_one_primary on emergency_contacts (person_id) where is_primary;

-- Never store a full ID number here (Aadhaar in particular has legal limits).
-- Keep the document type, the last 4 characters and the private file.
create table person_documents (
  id               uuid primary key default gen_random_uuid(),
  person_id        uuid not null references persons (id),
  document_type_id smallint not null references document_types (id),
  number_last4     text check (number_last4 ~ '^[A-Za-z0-9]{1,4}$'),
  file_id          uuid references files (id),
  verified_by      uuid references persons (id),
  verified_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- M2. PGs and who can work on them
--  A PG has no "owner_id" column. People are linked through pg_members with
--  a role, so co-owners, managers and caretakers need no structure change.
-- ---------------------------------------------------------------------
create table pgs (
  id            uuid primary key default gen_random_uuid(),
  name          text not null check (length(trim(name)) > 0),
  address_id    uuid references addresses (id),
  contact_phone text check (contact_phone ~ '^\+[1-9][0-9]{7,14}$'),
  gender_policy text not null default 'any' check (gender_policy in ('men', 'women', 'any')),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table pg_members (
  id         uuid primary key default gen_random_uuid(),
  pg_id      uuid not null references pgs (id),
  person_id  uuid not null references persons (id),
  role_id    smallint not null references roles (id),
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (pg_id, person_id)
);

-- Per-PG settings: one row per PG. Add a column when a new setting appears.
create table pg_billing_settings (
  pg_id                  uuid primary key references pgs (id) on delete cascade,
  default_billing_day    smallint not null default 1 check (default_billing_day between 1 and 28),
  grace_days             smallint not null default 0 check (grace_days >= 0),
  late_fee_paise_per_day bigint   not null default 0 check (late_fee_paise_per_day >= 0),
  updated_at             timestamptz not null default now()
);

-- Where the owner receives money. A PG can have many (several UPI IDs, banks).
create table pg_payment_accounts (
  id            uuid primary key default gen_random_uuid(),
  pg_id         uuid not null references pgs (id),
  nickname      text not null,                 -- e.g. "SBI - Ramesh"
  kind          text not null check (kind in ('upi', 'bank')),
  upi_vpa       text,
  bank_name     text,
  account_last4 text check (account_last4 ~ '^[0-9]{1,4}$'),
  holder_name   text,
  linked_phone  text check (linked_phone ~ '^\+[1-9][0-9]{7,14}$'),
  is_default    boolean not null default false,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (pg_id, nickname),
  check ((kind = 'upi' and upi_vpa is not null) or (kind = 'bank' and bank_name is not null))
);
create unique index pg_payment_accounts_one_default on pg_payment_accounts (pg_id) where is_default;

-- Reminder timing is data, not code. Negative = days before the due date.
create table reminder_rules (
  id            uuid primary key default gen_random_uuid(),
  pg_id         uuid not null references pgs (id) on delete cascade,
  days_from_due smallint not null check (days_from_due between -30 and 60),
  channel       text not null check (channel in ('push', 'sms', 'whatsapp')),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (pg_id, days_from_due, channel)
);


-- ---------------------------------------------------------------------
-- M3. Rooms and beds
-- ---------------------------------------------------------------------
create table rooms (
  id           uuid primary key default gen_random_uuid(),
  pg_id        uuid not null references pgs (id),
  room_number  text not null,
  floor        smallint,
  room_type_id smallint references room_types (id),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (pg_id, room_number)
);

-- Junction table: a room has many amenities, an amenity is in many rooms.
create table room_amenities (
  room_id    uuid not null references rooms (id),
  amenity_id smallint not null references amenities (id),
  primary key (room_id, amenity_id)
);

create table beds (
  id         uuid primary key default gen_random_uuid(),
  room_id    uuid not null references rooms (id),
  label      text not null,                    -- "A", "B", "1" ...
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (room_id, label)
);


-- ---------------------------------------------------------------------
-- M4. Stays  (one row per person per visit to a PG)
--  Person = who. Stay = when/where/at what terms. Charges and payments hang
--  off the stay, so moving to another PG is just a new stay for the same
--  person and the old stay stays as history.
-- ---------------------------------------------------------------------
create table stays (
  id              uuid primary key default gen_random_uuid(),
  pg_id           uuid not null references pgs (id),
  person_id       uuid not null references persons (id),
  status          text not null default 'active'
                    check (status in ('reserved', 'active', 'notice', 'vacated')),
  join_date       date not null,
  billing_starts_on date,                        -- null = bill from join_date. Set it when moving an
                                                 -- existing tenant into the app, so old months are not billed again
  billing_day     smallint not null check (billing_day between 1 and 28),
  notice_given_on date,
  leave_date      date,
  created_by      uuid references persons (id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (leave_date is null or leave_date >= join_date),
  check (status <> 'vacated' or leave_date is not null)
);
-- A person can have only one open stay in a given PG.
create unique index stays_one_open_per_person_pg on stays (pg_id, person_id) where status <> 'vacated';

-- Bed history inside a stay (room changes keep the old rows).
create table stay_bed_assignments (
  id         uuid primary key default gen_random_uuid(),
  stay_id    uuid not null references stays (id),
  bed_id     uuid not null references beds (id),
  from_date  date not null,
  to_date    date,
  created_at timestamptz not null default now(),
  check (to_date is null or to_date >= from_date)
);
create unique index bed_has_one_current_occupant on stay_bed_assignments (bed_id)  where to_date is null;
create unique index stay_has_one_current_bed     on stay_bed_assignments (stay_id) where to_date is null;

-- Rent history: a rent change adds a row, it never overwrites the old rent.
create table stay_rent_terms (
  id                 uuid primary key default gen_random_uuid(),
  stay_id            uuid not null references stays (id),
  monthly_rent_paise bigint not null check (monthly_rent_paise >= 0),
  effective_from     date not null,
  created_by         uuid references persons (id),
  created_at         timestamptz not null default now(),
  unique (stay_id, effective_from)
);


-- ---------------------------------------------------------------------
-- M5. Billing  (charges = what is owed, payments = money received,
--               allocations = which payment paid which charge)
-- ---------------------------------------------------------------------
create table charges (
  id                  uuid primary key default gen_random_uuid(),
  stay_id             uuid not null references stays (id),
  charge_type_id      smallint not null references charge_types (id),
  period_month        date check (period_month is null or extract(day from period_month) = 1),
  description         text,
  amount_paise        bigint not null check (amount_paise > 0),
  due_date            date not null,            -- snapshot: stays.billing_day may change later
  is_system_generated boolean not null default false,
  voided_at           timestamptz,
  void_reason         text,
  created_by          uuid references persons (id),   -- null = created by the scheduler
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check ((voided_at is null) = (void_reason is null))
);
-- The monthly job can run twice without creating duplicate rent.
create unique index charges_one_system_charge_per_month
  on charges (stay_id, charge_type_id, period_month)
  where is_system_generated and voided_at is null;

create table payments (
  id                  uuid primary key default gen_random_uuid(),
  stay_id             uuid not null references stays (id),
  payment_method_id   smallint not null references payment_methods (id),
  amount_paise        bigint not null check (amount_paise > 0),
  paid_on             date not null,
  received_account_id uuid references pg_payment_accounts (id),   -- null for cash
  status              text not null default 'pending'
                        check (status in ('pending', 'confirmed', 'rejected', 'reversed')),
  status_reason       text,
  note                text,
  created_by          uuid references persons (id),
  confirmed_by        uuid references persons (id),
  confirmed_at        timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check (status not in ('confirmed', 'reversed') or (confirmed_by is not null and confirmed_at is not null)),
  check (status not in ('rejected', 'reversed') or status_reason is not null)
);

-- Optional UPI details. Cash payments have no row here. A future
-- payment_bank_details / payment_cheque_details table would follow the same shape.
create table payment_upi_details (
  payment_id         uuid primary key references payments (id),
  payer_app_id       smallint references upi_apps (id),
  payer_upi_id       text,
  payer_phone        text check (payer_phone ~ '^\+[1-9][0-9]{7,14}$'),
  utr                text,
  screenshot_file_id uuid references files (id),
  created_at         timestamptz not null default now()
);
create index payment_upi_details_utr on payment_upi_details (utr) where utr is not null;

create table payment_allocations (
  payment_id   uuid not null references payments (id),
  charge_id    uuid not null references charges (id),
  amount_paise bigint not null check (amount_paise > 0),
  created_at   timestamptz not null default now(),
  primary key (payment_id, charge_id)
);

create table receipts (
  id         uuid primary key default gen_random_uuid(),
  payment_id uuid not null unique references payments (id),
  receipt_no bigint generated always as identity unique,
  file_id    uuid references files (id),
  issued_at  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- M6. Communication (reads from billing; billing never calls this module)
-- ---------------------------------------------------------------------
create table device_tokens (
  id           uuid primary key default gen_random_uuid(),
  person_id    uuid not null references persons (id),
  token        text not null unique,
  platform     text not null check (platform in ('android', 'ios', 'web')),
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now()
);

create table notifications (
  id               uuid primary key default gen_random_uuid(),
  person_id        uuid not null references persons (id),
  kind             text not null check (kind in (
                     'rent_reminder', 'payment_reported', 'payment_confirmed',
                     'payment_rejected', 'announcement', 'system')),
  title            text not null,
  body             text not null,
  stay_id          uuid references stays (id),
  charge_id        uuid references charges (id),
  reminder_rule_id uuid references reminder_rules (id),
  channel          text not null check (channel in ('in_app', 'push', 'sms', 'whatsapp')),
  status           text not null default 'queued' check (status in ('queued', 'sent', 'failed', 'read')),
  scheduled_for    timestamptz not null default now(),
  sent_at          timestamptz,
  read_at          timestamptz,
  created_at       timestamptz not null default now()
);
-- Each reminder rule fires at most once per charge.
create unique index notifications_one_per_rule_and_charge
  on notifications (charge_id, reminder_rule_id) where reminder_rule_id is not null;


-- ---------------------------------------------------------------------
-- M7. Platform: audit trail (append-only)
--  jsonb is fine here because this is a log, not business data.
-- ---------------------------------------------------------------------
create table audit_log (
  id              bigint generated always as identity primary key,
  occurred_at     timestamptz not null default now(),
  actor_person_id uuid,                       -- null = system / scheduler
  table_name      text not null,
  record_id       text not null,
  action          text not null check (action in ('insert', 'update', 'delete')),
  old_data        jsonb,
  new_data        jsonb
);


-- ---------------------------------------------------------------------
-- Indexes for the lookups the app does all day (Postgres does not index
-- foreign keys by itself)
-- ---------------------------------------------------------------------
create index pg_members_person_idx          on pg_members (person_id) where is_active;
create index rooms_pg_idx                   on rooms (pg_id);
create index beds_room_idx                  on beds (room_id);
create index stays_pg_status_idx            on stays (pg_id, status);
create index stays_person_idx               on stays (person_id);
create index stay_bed_assignments_stay_idx  on stay_bed_assignments (stay_id);
create index stay_rent_terms_stay_idx       on stay_rent_terms (stay_id, effective_from desc);
create index charges_stay_due_idx           on charges (stay_id, due_date);
create index charges_due_idx                on charges (due_date) where voided_at is null;
create index payments_stay_status_idx       on payments (stay_id, status);
create index payments_paid_on_idx           on payments (paid_on);
create index payments_account_idx           on payments (received_account_id) where received_account_id is not null;
create index payment_allocations_charge_idx on payment_allocations (charge_id);
create index emergency_contacts_person_idx  on emergency_contacts (person_id);
create index person_documents_person_idx    on person_documents (person_id);
create index notifications_person_idx       on notifications (person_id, status);
create index device_tokens_person_idx       on device_tokens (person_id);
create index audit_log_record_idx           on audit_log (table_name, record_id);
create index audit_log_time_idx             on audit_log (occurred_at);


-- ---------------------------------------------------------------------
-- Who is the signed-in person?  (used by triggers, policies and functions)
-- ---------------------------------------------------------------------
create or replace function current_person_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from persons where auth_user_id = auth.uid()
$$;

create or replace function is_pg_staff(p_pg_id uuid, p_roles text[] default null) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from pg_members m
    join roles r on r.id = m.role_id
    where m.pg_id = p_pg_id
      and m.person_id = current_person_id()
      and m.is_active
      and (p_roles is null or r.code = any (p_roles))
  )
$$;

-- Used by policies. They are SECURITY DEFINER so that one table's policy can
-- look at another table without triggering that table's policy again
-- (which would loop forever).
create or replace function has_stay_in_pg(p_pg_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from stays s where s.pg_id = p_pg_id and s.person_id = current_person_id())
$$;

create or replace function has_open_stay_in_pg(p_pg_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from stays s
                 where s.pg_id = p_pg_id and s.person_id = current_person_id() and s.status <> 'vacated')
$$;

-- Basic identity (name, phone): visible to a PG the person has stayed in.
create or replace function is_pg_tenant_any(p_person_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from stays s where s.person_id = p_person_id and is_pg_staff(s.pg_id))
$$;

-- Sensitive details (ID proofs, emergency contacts): only while the person lives there.
create or replace function is_pg_tenant_open(p_person_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from stays s
                 where s.person_id = p_person_id and s.status <> 'vacated' and is_pg_staff(s.pg_id))
$$;

create or replace function is_pg_colleague(p_person_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from pg_members m where m.person_id = p_person_id and is_pg_staff(m.pg_id))
$$;

create or replace function can_see_stay(p_stay_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from stays s
                 where s.id = p_stay_id and (s.person_id = current_person_id() or is_pg_staff(s.pg_id)))
$$;

create or replace function can_see_payment(p_payment_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from payments p where p.id = p_payment_id and can_see_stay(p.stay_id))
$$;

create or replace function can_see_room(p_room_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from rooms r
    where r.id = p_room_id
      and (is_pg_staff(r.pg_id)
           or exists (select 1
                      from beds b
                      join stay_bed_assignments a on a.bed_id = b.id and a.to_date is null
                      join stays s on s.id = a.stay_id
                      where b.room_id = r.id and s.person_id = current_person_id()))
  )
$$;

create or replace function can_manage_room(p_room_id uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from rooms r
                 where r.id = p_room_id and is_pg_staff(r.pg_id, array['owner', 'manager']))
$$;


-- ---------------------------------------------------------------------
-- Integrity guards (rules the database enforces even if the app has a bug)
-- ---------------------------------------------------------------------

-- Nothing important is ever deleted. Use a status / end date / void instead.
create or replace function block_delete() returns trigger
language plpgsql as $$
begin
  raise exception 'Rows in % cannot be %. History is kept: change the status or void the row instead.',
    tg_table_name, case tg_op when 'DELETE' then 'deleted' else 'edited' end
    using errcode = 'P0001';
end $$;

-- Confirmed money cannot be edited. Allowed status moves:
--   pending -> confirmed | rejected,   confirmed -> reversed
create or replace function guard_payment_update() returns trigger
language plpgsql as $$
begin
  if old.status <> 'pending'
     and (new.stay_id, new.amount_paise, new.paid_on, new.payment_method_id)
         is distinct from (old.stay_id, old.amount_paise, old.paid_on, old.payment_method_id) then
    raise exception 'A confirmed payment cannot be edited. Reverse it and enter it again.'
      using errcode = 'P0001';
  end if;
  if new.status is distinct from old.status
     and not ((old.status = 'pending' and new.status in ('confirmed', 'rejected'))
              or (old.status = 'confirmed' and new.status = 'reversed')) then
    raise exception 'A % payment cannot become %', old.status, new.status using errcode = 'P0001';
  end if;
  return new;
end $$;

-- The receiving account must belong to the same PG as the stay.
create or replace function check_payment_account() returns trigger
language plpgsql as $$
begin
  if new.received_account_id is not null and not exists (
       select 1
       from pg_payment_accounts a
       join stays s on s.pg_id = a.pg_id
       where a.id = new.received_account_id and s.id = new.stay_id) then
    raise exception 'That receiving account belongs to a different PG' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- A bed can only be given to a stay of the same PG.
create or replace function check_bed_assignment() returns trigger
language plpgsql as $$
declare
  v_stay_pg uuid;
  v_bed_pg  uuid;
begin
  select pg_id into v_stay_pg from stays where id = new.stay_id;
  select r.pg_id into v_bed_pg from beds b join rooms r on r.id = b.room_id where b.id = new.bed_id;
  if v_stay_pg is distinct from v_bed_pg then
    raise exception 'That bed belongs to a different PG' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- A payment can only pay charges of its own stay, and never more than it is worth
-- or more than the charge is worth.
create or replace function check_allocation() returns trigger
language plpgsql as $$
declare
  v_pay_amount  bigint;
  v_pay_status  text;
  v_pay_stay    uuid;
  v_chg_amount  bigint;
  v_chg_stay    uuid;
  v_chg_void    timestamptz;
  v_pay_used    bigint;
  v_chg_used    bigint;
begin
  select amount_paise, status, stay_id into v_pay_amount, v_pay_status, v_pay_stay
    from payments where id = new.payment_id for update;
  select amount_paise, stay_id, voided_at into v_chg_amount, v_chg_stay, v_chg_void
    from charges where id = new.charge_id for update;

  if v_pay_status <> 'confirmed' then
    raise exception 'Only a confirmed payment can be allocated' using errcode = 'P0001';
  end if;
  if v_pay_stay <> v_chg_stay then
    raise exception 'Payment and charge belong to different stays' using errcode = 'P0001';
  end if;
  if v_chg_void is not null then
    raise exception 'A voided charge cannot be paid' using errcode = 'P0001';
  end if;

  -- allocations that sit on voided charges are free again, so they do not count as used
  select coalesce(sum(a.amount_paise), 0) into v_pay_used
    from payment_allocations a join charges c on c.id = a.charge_id
    where a.payment_id = new.payment_id and c.voided_at is null;
  select coalesce(sum(a.amount_paise), 0) into v_chg_used
    from payment_allocations a join payments p on p.id = a.payment_id
    where a.charge_id = new.charge_id and p.status = 'confirmed';

  if v_pay_used + new.amount_paise > v_pay_amount then
    raise exception 'Allocation is larger than the payment' using errcode = 'P0001';
  end if;
  if v_chg_used + new.amount_paise > v_chg_amount then
    raise exception 'Allocation is larger than the charge' using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger trg_payments_guard_update
  before update on payments for each row execute function guard_payment_update();
create trigger trg_payments_check_account
  before insert or update of received_account_id, stay_id on payments
  for each row execute function check_payment_account();
create trigger trg_bed_assignment_check
  before insert on stay_bed_assignments for each row execute function check_bed_assignment();
create trigger trg_allocation_check
  before insert on payment_allocations for each row execute function check_allocation();

-- Copy every change on important tables into audit_log.
create or replace function audit_row_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
begin
  if tg_op = 'UPDATE' and v_old = v_new then
    return null;
  end if;
  insert into audit_log (actor_person_id, table_name, record_id, action, old_data, new_data)
  values (current_person_id(), tg_table_name,
          coalesce(v_new, v_old) ->> 'id'
            , lower(tg_op), v_old, v_new);
  return null;
end $$;

do $$
declare
  t text;
begin
  -- keep updated_at honest
  foreach t in array array[
    'persons', 'emergency_contacts', 'person_documents', 'pgs', 'pg_members',
    'pg_billing_settings', 'pg_payment_accounts', 'reminder_rules', 'rooms', 'beds',
    'stays', 'charges', 'payments'] loop
    execute format('create trigger trg_%1$s_updated_at before update on %1$I
                    for each row execute function set_updated_at()', t);
  end loop;

  -- audit trail
  foreach t in array array[
    'persons', 'emergency_contacts', 'person_documents', 'pgs', 'pg_members',
    'pg_payment_accounts', 'reminder_rules', 'rooms', 'beds', 'stays',
    'stay_bed_assignments', 'stay_rent_terms', 'charges', 'payments'] loop
    execute format('create trigger trg_%1$s_audit after insert or update or delete on %1$I
                    for each row execute function audit_row_change()', t);
  end loop;

  -- no hard deletes on history
  foreach t in array array[
    'persons', 'stays', 'stay_bed_assignments', 'stay_rent_terms', 'charges',
    'payments', 'payment_allocations', 'receipts'] loop
    execute format('create trigger trg_%1$s_no_delete before delete on %1$I
                    for each row execute function block_delete()', t);
  end loop;
end $$;

-- audit_log itself is append-only.
create trigger trg_audit_log_append_only
  before update or delete on audit_log for each row execute function block_delete();


-- ---------------------------------------------------------------------
-- Views = the read side of the "database contract".
--  The app reads these, not the raw tables, so tables can be reorganised
--  later without touching the app. security_invoker makes each view obey the
--  row-level security of the person who is asking.
-- ---------------------------------------------------------------------

-- One row per charge with how much is paid and its status:
-- paid | partial | due | overdue | void
create or replace view v_charge_balances with (security_invoker = true) as
select
  c.id            as charge_id,
  c.stay_id,
  c.charge_type_id,
  c.period_month,
  c.description,
  c.due_date,
  c.amount_paise,
  coalesce(a.paid_paise, 0) as paid_paise,
  case when c.voided_at is not null then 0
       else c.amount_paise - coalesce(a.paid_paise, 0) end as outstanding_paise,
  case
    when c.voided_at is not null                         then 'void'
    when c.amount_paise - coalesce(a.paid_paise, 0) <= 0 then 'paid'
    when c.due_date < today_ist()                        then 'overdue'
    when coalesce(a.paid_paise, 0) > 0                   then 'partial'
    else 'due'
  end as status
from charges c
left join lateral (
  select sum(pa.amount_paise)::bigint as paid_paise
  from payment_allocations pa
  join payments p on p.id = pa.payment_id
  where pa.charge_id = c.id and p.status = 'confirmed'
) a on true;

-- One row per stay: the numbers for the tenant home screen and the owner list.
--   credit_paise = confirmed money not yet used against any charge (advance paid)
create or replace view v_stay_balances with (security_invoker = true) as
select
  s.id        as stay_id,
  s.pg_id,
  s.person_id,
  s.status    as stay_status,
  coalesce(cb.charged_paise, 0)     as charged_paise,
  coalesce(cb.paid_paise, 0)        as paid_against_charges_paise,
  coalesce(cb.outstanding_paise, 0) as outstanding_paise,
  coalesce(cb.overdue_paise, 0)     as overdue_paise,
  cb.oldest_unpaid_due_date,
  coalesce(p.confirmed_paise, 0) - coalesce(cb.paid_paise, 0) as credit_paise,
  coalesce(p.pending_paise, 0)      as pending_verification_paise
from stays s
left join (
  select stay_id,
         (sum(amount_paise)      filter (where status <> 'void'))::bigint   as charged_paise,
         (sum(paid_paise)        filter (where status <> 'void'))::bigint   as paid_paise,
         (sum(outstanding_paise) filter (where status <> 'void'))::bigint   as outstanding_paise,
         (sum(outstanding_paise) filter (where status = 'overdue'))::bigint as overdue_paise,
         min(due_date)          filter (where status in ('due', 'partial', 'overdue')) as oldest_unpaid_due_date
  from v_charge_balances
  group by stay_id
) cb on cb.stay_id = s.id
left join (
  select stay_id,
         (sum(amount_paise) filter (where status = 'confirmed'))::bigint as confirmed_paise,
         (sum(amount_paise) filter (where status = 'pending'))::bigint   as pending_paise
  from payments
  group by stay_id
) p on p.stay_id = s.id;

-- Owner dashboard: expected / collected / pending / overdue per PG per month.
create or replace view v_pg_monthly_summary with (security_invoker = true) as
select
  s.pg_id,
  cb.period_month,
  count(distinct cb.stay_id)                                        as tenants_billed,
  sum(cb.amount_paise)::bigint                                      as expected_paise,
  sum(cb.paid_paise)::bigint                                        as collected_paise,
  sum(cb.outstanding_paise)::bigint                                 as pending_paise,
  coalesce(sum(cb.outstanding_paise) filter (where cb.status = 'overdue'), 0)::bigint as overdue_paise
from v_charge_balances cb
join stays s on s.id = cb.stay_id
where cb.status <> 'void' and cb.period_month is not null
group by s.pg_id, cb.period_month;

-- "Which account did the money go to?" by month and method.
create or replace view v_collections_by_account with (security_invoker = true) as
select
  s.pg_id,
  p.received_account_id,
  a.nickname                         as account_nickname,
  pm.code                            as method_code,
  date_trunc('month', p.paid_on)::date as month,
  count(*)                           as payment_count,
  sum(p.amount_paise)::bigint        as total_paise
from payments p
join stays s            on s.id  = p.stay_id
join payment_methods pm on pm.id = p.payment_method_id
left join pg_payment_accounts a on a.id = p.received_account_id
where p.status = 'confirmed'
group by s.pg_id, p.received_account_id, a.nickname, pm.code, date_trunc('month', p.paid_on)::date;


-- ---------------------------------------------------------------------
-- Link a login to a person (Supabase). If an owner already added this phone
-- number, the existing person is linked; otherwise a new person is created.
-- Having a person row does NOT give access to anything: access comes only
-- from pg_members and stays.
-- ---------------------------------------------------------------------
create or replace function handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_phone text := normalize_phone('+' || ltrim(coalesce(new.phone, ''), '+'));
begin
  if v_phone is null then
    return new;
  end if;
  insert into persons (auth_user_id, phone)
  values (new.id, v_phone)
  on conflict (phone) do update
    set auth_user_id = excluded.auth_user_id
    where persons.auth_user_id is null;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users for each row execute function handle_new_auth_user();


-- ---------------------------------------------------------------------
-- Row-level security: the database itself decides who sees which rows.
--  * Every table has RLS on. A table with no policy = nobody (except the
--    server-side service role) can read it.
--  * Money and stay tables have SELECT policies only. They are written ONLY
--    through the rpc_* functions in 002_core_functions.sql.
-- ---------------------------------------------------------------------
do $$
declare
  t record;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t.tablename);
  end loop;
end $$;

-- Reference data: any signed-in user can read, nobody can write from the app.
do $$
declare
  t text;
begin
  foreach t in array array[
    'roles', 'payment_methods', 'charge_types', 'room_types', 'amenities',
    'document_types', 'relationship_types', 'upi_apps', 'states', 'cities'] loop
    execute format('create policy %I on %I for select to authenticated using (true)', t || '_read', t);
  end loop;
end $$;

-- addresses: visible with the PG they belong to
create policy addresses_read on addresses for select to authenticated
  using (exists (select 1 from pgs p where p.address_id = addresses.id));
create policy addresses_update on addresses for update to authenticated
  using (exists (select 1 from pgs p where p.address_id = addresses.id and is_pg_staff(p.id, array['owner'])));

-- persons
create policy persons_read on persons for select to authenticated
  using (id = current_person_id() or is_pg_tenant_any(id) or is_pg_colleague(id));
create policy persons_update_self on persons for update to authenticated
  using (id = current_person_id()) with check (id = current_person_id());

-- personal details of a person: the person, or the staff of the PG they live in now
create policy emergency_contacts_all on emergency_contacts for all to authenticated
  using (person_id = current_person_id() or is_pg_tenant_open(person_id))
  with check (person_id = current_person_id() or is_pg_tenant_open(person_id));
create policy person_documents_all on person_documents for all to authenticated
  using (person_id = current_person_id() or is_pg_tenant_open(person_id))
  with check (person_id = current_person_id() or is_pg_tenant_open(person_id));

-- files: the uploader, or the PG staff that the file is about
create policy files_read on files for select to authenticated
  using (
    uploaded_by = current_person_id()
    or exists (select 1 from persons pr where pr.photo_file_id = files.id and is_pg_tenant_any(pr.id))
    or exists (select 1 from person_documents d where d.file_id = files.id and is_pg_tenant_open(d.person_id))
    or exists (select 1
               from payment_upi_details u
               join payments p on p.id = u.payment_id
               join stays s on s.id = p.stay_id
               where u.screenshot_file_id = files.id and is_pg_staff(s.pg_id))
  );
create policy files_insert on files for insert to authenticated
  with check (uploaded_by = current_person_id());

-- PGs and their staff
create policy pgs_read on pgs for select to authenticated
  using (is_pg_staff(id) or has_stay_in_pg(id));
create policy pgs_update on pgs for update to authenticated
  using (is_pg_staff(id, array['owner'])) with check (is_pg_staff(id, array['owner']));

create policy pg_members_read on pg_members for select to authenticated
  using (is_pg_staff(pg_id) or person_id = current_person_id());
create policy pg_members_insert on pg_members for insert to authenticated
  with check (is_pg_staff(pg_id, array['owner']));
create policy pg_members_update on pg_members for update to authenticated
  using (is_pg_staff(pg_id, array['owner'])) with check (is_pg_staff(pg_id, array['owner']));

create policy pg_billing_settings_read on pg_billing_settings for select to authenticated
  using (is_pg_staff(pg_id));
create policy pg_billing_settings_update on pg_billing_settings for update to authenticated
  using (is_pg_staff(pg_id, array['owner'])) with check (is_pg_staff(pg_id, array['owner']));

-- tenants with an open stay can see active receiving accounts (they need them to pay)
create policy pg_payment_accounts_read on pg_payment_accounts for select to authenticated
  using (is_pg_staff(pg_id) or (is_active and has_open_stay_in_pg(pg_id)));
create policy pg_payment_accounts_insert on pg_payment_accounts for insert to authenticated
  with check (is_pg_staff(pg_id, array['owner']));
create policy pg_payment_accounts_update on pg_payment_accounts for update to authenticated
  using (is_pg_staff(pg_id, array['owner'])) with check (is_pg_staff(pg_id, array['owner']));

create policy reminder_rules_read on reminder_rules for select to authenticated
  using (is_pg_staff(pg_id));
create policy reminder_rules_write on reminder_rules for all to authenticated
  using (is_pg_staff(pg_id, array['owner'])) with check (is_pg_staff(pg_id, array['owner']));

-- rooms and beds: staff see all, a tenant sees only their own room
create policy rooms_read on rooms for select to authenticated using (can_see_room(id));
create policy rooms_insert on rooms for insert to authenticated
  with check (is_pg_staff(pg_id, array['owner', 'manager']));
create policy rooms_update on rooms for update to authenticated
  using (is_pg_staff(pg_id, array['owner', 'manager']))
  with check (is_pg_staff(pg_id, array['owner', 'manager']));

create policy beds_read on beds for select to authenticated using (can_see_room(room_id));
create policy beds_insert on beds for insert to authenticated with check (can_manage_room(room_id));
create policy beds_update on beds for update to authenticated
  using (can_manage_room(room_id)) with check (can_manage_room(room_id));

create policy room_amenities_read on room_amenities for select to authenticated using (can_see_room(room_id));
create policy room_amenities_insert on room_amenities for insert to authenticated with check (can_manage_room(room_id));
create policy room_amenities_delete on room_amenities for delete to authenticated using (can_manage_room(room_id));

-- stays and billing: read-only from the app (changes go through rpc_* functions)
create policy stays_read on stays for select to authenticated
  using (person_id = current_person_id() or is_pg_staff(pg_id));
create policy stay_bed_assignments_read on stay_bed_assignments for select to authenticated
  using (can_see_stay(stay_id));
create policy stay_rent_terms_read on stay_rent_terms for select to authenticated
  using (can_see_stay(stay_id));
create policy charges_read on charges for select to authenticated
  using (can_see_stay(stay_id));
create policy payments_read on payments for select to authenticated
  using (can_see_stay(stay_id));
create policy payment_upi_details_read on payment_upi_details for select to authenticated
  using (can_see_payment(payment_id));
create policy payment_allocations_read on payment_allocations for select to authenticated
  using (can_see_payment(payment_id));
create policy receipts_read on receipts for select to authenticated
  using (can_see_payment(payment_id));

-- comms: a person sees only their own
create policy device_tokens_all on device_tokens for all to authenticated
  using (person_id = current_person_id()) with check (person_id = current_person_id());
create policy notifications_read on notifications for select to authenticated
  using (person_id = current_person_id());
create policy notifications_update on notifications for update to authenticated
  using (person_id = current_person_id()) with check (person_id = current_person_id());

-- audit_log: no policy on purpose. Only the server (service role) can read it.


-- ---------------------------------------------------------------------
-- Privileges: start from nothing, then grant only what the app needs.
--  RLS decides WHICH rows; these grants decide WHAT KIND of access.
-- ---------------------------------------------------------------------
revoke all on all tables    in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

-- Future functions are locked by default too: grant execute explicitly,
-- one function at a time, only for what the app really calls.
-- (Two statements on purpose: PostgreSQL gives EXECUTE to PUBLIC through a global
--  default that "IN SCHEMA" cannot remove, while Supabase adds its own
--  schema-level defaults for anon / authenticated.)
alter default privileges revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon, authenticated;

grant select on all tables in schema public to authenticated;

-- A signed-in person may edit only these profile fields (phone and identity are fixed):
grant update (full_name, email, photo_file_id) on persons to authenticated;
grant insert, update, delete on emergency_contacts, person_documents, device_tokens to authenticated;
grant insert on files to authenticated;
grant update (name, contact_phone, gender_policy) on pgs to authenticated;
grant update (line1, line2, area, city_id, pincode, latitude, longitude) on addresses to authenticated;
grant insert, update on pg_members, pg_payment_accounts, rooms, beds to authenticated;
grant update on pg_billing_settings to authenticated;
grant insert, update, delete on reminder_rules to authenticated;
grant insert, delete on room_amenities to authenticated;
grant update (status, read_at) on notifications to authenticated;

-- Helpers that policies and views call must be executable by signed-in users.
grant execute on function
  current_person_id(), is_pg_staff(uuid, text[]), has_stay_in_pg(uuid), has_open_stay_in_pg(uuid),
  is_pg_tenant_any(uuid), is_pg_tenant_open(uuid), is_pg_colleague(uuid),
  can_see_stay(uuid), can_see_payment(uuid), can_see_room(uuid), can_manage_room(uuid),
  today_ist(), normalize_phone(text)
to authenticated;
