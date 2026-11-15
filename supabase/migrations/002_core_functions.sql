-- =====================================================================
--  PG Rent App  |  002_core_functions.sql
--  THE DATABASE CONTRACT: the only doors the app uses to CHANGE data.
-- ---------------------------------------------------------------------
--  Why functions instead of the app writing to tables directly?
--   * Each business rule (who may do it, what gets created together, how a
--     payment is split across charges) exists in ONE place. Android, iOS and a
--     future website all behave the same.
--   * The tables behind a function can be reorganised later. As long as the
--     function name, inputs and result stay the same, the app is untouched.
--   * A bug in the app cannot write half a record: each function runs as one
--     all-or-nothing transaction.
--
--  Every rpc_* function checks WHO is calling before it does anything.
--  Internal helpers (allocate_payment, apply_stay_credit) are not granted to
--  the app. rpc_generate_monthly_charges is for the scheduler only.
--
--  Changing a function's inputs or result breaks old app versions that are
--  still installed. Add a new function (or a new optional parameter with a
--  default) and retire the old one later.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Internal: split a confirmed payment across the stay's unpaid charges,
-- oldest due date first. Whatever is left stays as advance credit.
-- ---------------------------------------------------------------------
create or replace function allocate_payment(p_payment_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_pay  payments%rowtype;
  v_left bigint;
  v_row  record;
  v_take bigint;
begin
  select * into v_pay from payments where id = p_payment_id for update;
  if v_pay.id is null then
    raise exception 'Payment not found';
  end if;
  if v_pay.status <> 'confirmed' then
    raise exception 'Only a confirmed payment can be allocated';
  end if;

  perform 1 from stays where id = v_pay.stay_id for update;   -- one allocation at a time per stay

  select v_pay.amount_paise - coalesce(sum(a.amount_paise), 0) into v_left
  from payment_allocations a
  join charges c on c.id = a.charge_id
  where a.payment_id = p_payment_id and c.voided_at is null;

  for v_row in
    select cb.charge_id, cb.outstanding_paise
    from v_charge_balances cb
    join charges c on c.id = cb.charge_id
    where cb.stay_id = v_pay.stay_id and cb.status in ('due', 'partial', 'overdue')
    order by cb.due_date, c.created_at, c.id
  loop
    exit when v_left <= 0;
    v_take := least(v_left, v_row.outstanding_paise);
    insert into payment_allocations (payment_id, charge_id, amount_paise)
    values (p_payment_id, v_row.charge_id, v_take);
    v_left := v_left - v_take;
  end loop;
end $$;

-- Internal: put any unused confirmed money of a stay to work on unpaid charges.
-- Called after new charges appear or after a payment is reversed / a charge voided.
create or replace function apply_stay_credit(p_stay_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  for v_id in
    select id from payments
    where stay_id = p_stay_id and status = 'confirmed'
    order by paid_on, created_at, id
  loop
    perform allocate_payment(v_id);
  end loop;
end $$;


-- ---------------------------------------------------------------------
-- Who am I and what can I see?  The app calls this right after login to
-- decide which screens to show (owner view, tenant view, both, or
-- "ask your PG owner to add you").
-- ---------------------------------------------------------------------
create or replace function rpc_my_context() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'person', (select to_jsonb(p) - 'auth_user_id' from persons p where p.id = current_person_id()),
    'pgs', coalesce((
      select jsonb_agg(jsonb_build_object('pg_id', g.id, 'name', g.name, 'role', r.code) order by g.name)
      from pg_members m
      join pgs g   on g.id = m.pg_id
      join roles r on r.id = m.role_id
      where m.person_id = current_person_id() and m.is_active and g.is_active
    ), '[]'::jsonb),
    'stays', coalesce((
      select jsonb_agg(jsonb_build_object(
               'stay_id', s.id, 'pg_id', s.pg_id, 'pg_name', g.name,
               'status', s.status, 'join_date', s.join_date, 'leave_date', s.leave_date)
             order by s.join_date desc)
      from stays s
      join pgs g on g.id = s.pg_id
      where s.person_id = current_person_id()
    ), '[]'::jsonb)
  )
$$;


-- ---------------------------------------------------------------------
-- Owner creates a PG. The caller becomes its owner. Default billing
-- settings and reminder rules are created with it.
-- ---------------------------------------------------------------------
create or replace function rpc_create_pg(
  p_name          text,
  p_line1         text,
  p_city_id       integer,
  p_pincode       text default null,
  p_area          text default null,
  p_contact_phone text default null,
  p_gender_policy text default 'any'
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_me   uuid := current_person_id();
  v_addr uuid;
  v_pg   uuid;
begin
  if v_me is null then
    raise exception 'Please sign in first' using errcode = '28000';
  end if;
  if coalesce(trim(p_name), '') = '' then
    raise exception 'Enter the PG name';
  end if;
  if coalesce(trim(p_line1), '') = '' then
    raise exception 'Enter the PG address';
  end if;

  insert into addresses (line1, area, city_id, pincode)
  values (trim(p_line1), nullif(trim(p_area), ''), p_city_id, nullif(trim(p_pincode), ''))
  returning id into v_addr;

  insert into pgs (name, address_id, contact_phone, gender_policy)
  values (trim(p_name), v_addr, normalize_phone(p_contact_phone), p_gender_policy)
  returning id into v_pg;

  insert into pg_members (pg_id, person_id, role_id)
  select v_pg, v_me, id from roles where code = 'owner';

  insert into pg_billing_settings (pg_id) values (v_pg);

  insert into reminder_rules (pg_id, days_from_due, channel)
  values (v_pg, -3, 'push'), (v_pg, 0, 'push'), (v_pg, 2, 'push');

  return v_pg;
end $$;


-- ---------------------------------------------------------------------
-- Owner adds a guest: finds or creates the person by phone number, then
-- creates the stay, rent terms, bed and the security-deposit charge in one go.
-- ---------------------------------------------------------------------
create or replace function rpc_create_stay(
  p_pg_id              uuid,
  p_phone              text,
  p_full_name          text,
  p_bed_id             uuid,
  p_join_date          date,
  p_monthly_rent_paise bigint,
  p_deposit_paise      bigint default 0,
  p_billing_day        smallint default null,
  p_billing_starts_on  date default null,      -- for guests who joined before the app: first date to bill from
  p_deposit_already_paid boolean default false -- true = deposit was received before the app (no money due)
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_me     uuid := current_person_id();
  v_phone  text := normalize_phone(p_phone);
  v_person uuid;
  v_stay   uuid;
  v_day    smallint;
  v_pay    uuid;
begin
  if not is_pg_staff(p_pg_id, array['owner', 'manager']) then
    raise exception 'You do not have access to this PG' using errcode = '42501';
  end if;
  if v_phone is null then
    raise exception 'Enter a valid mobile number';
  end if;
  if p_join_date is null then
    raise exception 'Enter the joining date';
  end if;
  if p_monthly_rent_paise is null or p_monthly_rent_paise < 0 then
    raise exception 'Enter the monthly rent';
  end if;

  insert into persons (phone, full_name)
  values (v_phone, nullif(trim(p_full_name), ''))
  on conflict (phone) do update
    set full_name = coalesce(persons.full_name, excluded.full_name)
  returning id into v_person;

  v_day := coalesce(p_billing_day, least(extract(day from p_join_date)::int, 28));

  insert into stays (pg_id, person_id, status, join_date, billing_starts_on, billing_day, created_by)
  values (p_pg_id, v_person, 'active', p_join_date, p_billing_starts_on, v_day, v_me)
  returning id into v_stay;

  insert into stay_rent_terms (stay_id, monthly_rent_paise, effective_from, created_by)
  values (v_stay, p_monthly_rent_paise, p_join_date, v_me);

  if p_bed_id is not null then
    insert into stay_bed_assignments (stay_id, bed_id, from_date)
    values (v_stay, p_bed_id, p_join_date);
  end if;

  if coalesce(p_deposit_paise, 0) > 0 then
    insert into charges (stay_id, charge_type_id, description, amount_paise, due_date, created_by)
    select v_stay, id, 'Security deposit', p_deposit_paise, p_join_date, v_me
    from charge_types where code = 'security_deposit';

    if p_deposit_already_paid then
      insert into payments (stay_id, payment_method_id, amount_paise, paid_on, status, note,
                            created_by, confirmed_by, confirmed_at)
      select v_stay, id, p_deposit_paise, p_join_date, 'confirmed', 'Received before using the app',
             v_me, v_me, now()
      from payment_methods where code = 'cash'
      returning id into v_pay;
      perform allocate_payment(v_pay);
    end if;
  end if;

  return v_stay;
end $$;


-- ---------------------------------------------------------------------
-- Owner changes the rent from a date. Old rent stays in history.
-- ---------------------------------------------------------------------
create or replace function rpc_set_stay_rent(
  p_stay_id            uuid,
  p_monthly_rent_paise bigint,
  p_effective_from     date
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_pg uuid;
begin
  select pg_id into v_pg from stays where id = p_stay_id;
  if v_pg is null or not is_pg_staff(v_pg, array['owner', 'manager']) then
    raise exception 'You do not have access to this stay' using errcode = '42501';
  end if;
  if p_monthly_rent_paise is null or p_monthly_rent_paise < 0 then
    raise exception 'Enter the monthly rent';
  end if;
  insert into stay_rent_terms (stay_id, monthly_rent_paise, effective_from, created_by)
  values (p_stay_id, p_monthly_rent_paise, p_effective_from, current_person_id());
end $$;


-- ---------------------------------------------------------------------
-- Scheduler only (pg_cron / Edge Function with the service role).
-- Creates the rent charge for a month for every open stay. Safe to run many
-- times: a stay never gets two rent charges for the same month. Advance
-- credit is applied to the new charge automatically.
-- Run it DAILY for the current month and the next month, so a guest added in
-- the middle of a month is picked up the same day.
-- Not granted to the app on purpose.
-- ---------------------------------------------------------------------
create or replace function rpc_generate_monthly_charges(p_month date default null)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_month date := date_trunc('month', coalesce(p_month, today_ist()))::date;
  v_stays uuid[];
  v_id    uuid;
begin
  with due as (
    select s.id as stay_id,
           make_date(extract(year from v_month)::int, extract(month from v_month)::int, s.billing_day) as due_date
    from stays s
    where s.status in ('active', 'notice')
  ),
  priced as (
    select d.stay_id,
           d.due_date,
           (select t.monthly_rent_paise
              from stay_rent_terms t
             where t.stay_id = d.stay_id and t.effective_from <= d.due_date
             order by t.effective_from desc
             limit 1) as rent_paise
    from due d
    join stays s on s.id = d.stay_id
    where d.due_date >= coalesce(s.billing_starts_on, s.join_date)
      and (s.leave_date is null or d.due_date <= s.leave_date)
  ),
  made as (
    insert into charges (stay_id, charge_type_id, period_month, description,
                         amount_paise, due_date, is_system_generated)
    select p.stay_id, ct.id, v_month, 'Rent for ' || to_char(v_month, 'Mon YYYY'),
           p.rent_paise, p.due_date, true
    from priced p
    join charge_types ct on ct.code = 'rent'
    where p.rent_paise > 0
    on conflict do nothing
    returning stay_id
  )
  select array_agg(stay_id) into v_stays from made;

  foreach v_id in array coalesce(v_stays, '{}'::uuid[]) loop
    perform apply_stay_credit(v_id);
  end loop;

  return coalesce(array_length(v_stays, 1), 0);
end $$;


-- ---------------------------------------------------------------------
-- Owner adds a one-off charge (electricity, laundry, damage ...).
-- ---------------------------------------------------------------------
create or replace function rpc_add_charge(
  p_stay_id          uuid,
  p_charge_type_code text,
  p_amount_paise     bigint,
  p_due_date         date,
  p_description      text default null,
  p_period_month     date default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_pg   uuid;
  v_type smallint;
  v_id   uuid;
begin
  select pg_id into v_pg from stays where id = p_stay_id;
  if v_pg is null or not is_pg_staff(v_pg, array['owner', 'manager']) then
    raise exception 'You do not have access to this stay' using errcode = '42501';
  end if;
  if p_amount_paise is null or p_amount_paise <= 0 then
    raise exception 'Enter an amount greater than zero';
  end if;
  select id into v_type from charge_types where code = p_charge_type_code and is_active;
  if v_type is null then
    raise exception 'Unknown charge type';
  end if;

  insert into charges (stay_id, charge_type_id, period_month, description, amount_paise, due_date, created_by)
  values (p_stay_id, v_type, p_period_month, p_description, p_amount_paise, p_due_date, current_person_id())
  returning id into v_id;

  perform apply_stay_credit(p_stay_id);
  return v_id;
end $$;

create or replace function rpc_void_charge(p_charge_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_stay uuid;
  v_pg   uuid;
begin
  select c.stay_id, s.pg_id into v_stay, v_pg
  from charges c join stays s on s.id = c.stay_id
  where c.id = p_charge_id;
  if v_pg is null or not is_pg_staff(v_pg, array['owner', 'manager']) then
    raise exception 'You do not have access to this charge' using errcode = '42501';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for cancelling this charge';
  end if;

  update charges set voided_at = now(), void_reason = trim(p_reason)
  where id = p_charge_id and voided_at is null;

  perform apply_stay_credit(v_stay);   -- money that was on this charge becomes available again
end $$;


-- ---------------------------------------------------------------------
-- PAYMENTS
--  Owner / staff records a payment: it is confirmed immediately (cash, or a
--  UPI payment the owner has seen in the bank). Optional UPI details.
-- ---------------------------------------------------------------------
create or replace function rpc_record_payment(
  p_stay_id        uuid,
  p_amount_paise   bigint,
  p_method_code    text,
  p_paid_on        date default null,
  p_account_id     uuid default null,
  p_note           text default null,
  p_payer_app_code text default null,
  p_utr            text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_me     uuid := current_person_id();
  v_pg     uuid;
  v_status text;
  v_method smallint;
  v_utr    text := nullif(upper(trim(coalesce(p_utr, ''))), '');
  v_pay    uuid;
begin
  select pg_id, status into v_pg, v_status from stays where id = p_stay_id;
  if v_pg is null or not is_pg_staff(v_pg, array['owner', 'manager', 'caretaker']) then
    raise exception 'You do not have access to this stay' using errcode = '42501';
  end if;
  if p_amount_paise is null or p_amount_paise <= 0 then
    raise exception 'Enter an amount greater than zero';
  end if;
  select id into v_method from payment_methods where code = p_method_code and is_active;
  if v_method is null then
    raise exception 'Unknown payment method';
  end if;
  if v_utr is not null and exists (
       select 1 from payment_upi_details d join payments p on p.id = d.payment_id
       where d.utr = v_utr and p.status in ('pending', 'confirmed')) then
    raise exception 'This UTR is already recorded for another payment' using errcode = '23505';
  end if;

  insert into payments (stay_id, payment_method_id, amount_paise, paid_on, received_account_id,
                        status, note, created_by, confirmed_by, confirmed_at)
  values (p_stay_id, v_method, p_amount_paise, coalesce(p_paid_on, today_ist()), p_account_id,
          'confirmed', p_note, v_me, v_me, now())
  returning id into v_pay;

  if p_method_code = 'upi' and (p_payer_app_code is not null or v_utr is not null) then
    insert into payment_upi_details (payment_id, payer_app_id, utr)
    values (v_pay, (select id from upi_apps where code = p_payer_app_code), v_utr);
  end if;

  perform allocate_payment(v_pay);
  insert into receipts (payment_id) values (v_pay);
  return v_pay;
end $$;

-- Tenant says "I have paid". Everything except the amount and method is
-- optional. The payment waits as 'pending' until the owner confirms it.
create or replace function rpc_report_payment(
  p_stay_id        uuid,
  p_amount_paise   bigint,
  p_method_code    text,
  p_paid_on        date default null,
  p_account_id     uuid default null,
  p_payer_app_code text default null,
  p_payer_phone    text default null,
  p_utr            text default null,
  p_note           text default null,
  p_screenshot_file_id uuid default null     -- optional: a files row the guest uploaded
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_me     uuid := current_person_id();
  v_person uuid;
  v_status text;
  v_method smallint;
  v_utr    text := nullif(upper(trim(coalesce(p_utr, ''))), '');
  v_pay    uuid;
begin
  select person_id, status into v_person, v_status from stays where id = p_stay_id;
  if v_person is null or v_person is distinct from v_me or v_status = 'vacated' then
    raise exception 'You cannot report a payment for this stay' using errcode = '42501';
  end if;
  if p_amount_paise is null or p_amount_paise <= 0 then
    raise exception 'Enter an amount greater than zero';
  end if;
  select id into v_method from payment_methods where code = p_method_code and is_active;
  if v_method is null then
    raise exception 'Unknown payment method';
  end if;
  if v_utr is not null and exists (
       select 1 from payment_upi_details d join payments p on p.id = d.payment_id
       where d.utr = v_utr and p.status in ('pending', 'confirmed')) then
    raise exception 'This UTR is already recorded for another payment' using errcode = '23505';
  end if;
  if p_screenshot_file_id is not null
     and not exists (select 1 from files where id = p_screenshot_file_id and uploaded_by = v_me) then
    raise exception 'The screenshot could not be found. Please upload it again';
  end if;

  insert into payments (stay_id, payment_method_id, amount_paise, paid_on, received_account_id,
                        status, note, created_by)
  values (p_stay_id, v_method, p_amount_paise, coalesce(p_paid_on, today_ist()), p_account_id,
          'pending', p_note, v_me)
  returning id into v_pay;

  -- optional details exist only for UPI payments
  if p_method_code = 'upi'
     and (p_payer_app_code is not null or p_payer_phone is not null
          or v_utr is not null or p_screenshot_file_id is not null) then
    insert into payment_upi_details (payment_id, payer_app_id, payer_phone, utr, screenshot_file_id)
    values (v_pay, (select id from upi_apps where code = p_payer_app_code),
            normalize_phone(p_payer_phone), v_utr, p_screenshot_file_id);
  end if;

  return v_pay;
end $$;

-- Owner confirms a pending payment. He may set or correct the account the money reached.
create or replace function rpc_confirm_payment(p_payment_id uuid, p_account_id uuid default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_pay payments%rowtype;
  v_pg  uuid;
begin
  select * into v_pay from payments where id = p_payment_id for update;
  select pg_id into v_pg from stays where id = v_pay.stay_id;
  if v_pay.id is null or not is_pg_staff(v_pg, array['owner', 'manager', 'caretaker']) then
    raise exception 'You do not have access to this payment' using errcode = '42501';
  end if;
  if v_pay.status <> 'pending' then
    raise exception 'This payment is already %', v_pay.status;
  end if;

  update payments
     set status = 'confirmed',
         confirmed_by = current_person_id(),
         confirmed_at = now(),
         received_account_id = coalesce(p_account_id, received_account_id)
   where id = p_payment_id;

  perform allocate_payment(p_payment_id);
  insert into receipts (payment_id) values (p_payment_id);
end $$;

create or replace function rpc_reject_payment(p_payment_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_pay payments%rowtype;
  v_pg  uuid;
begin
  select * into v_pay from payments where id = p_payment_id for update;
  select pg_id into v_pg from stays where id = v_pay.stay_id;
  if v_pay.id is null or not is_pg_staff(v_pg, array['owner', 'manager', 'caretaker']) then
    raise exception 'You do not have access to this payment' using errcode = '42501';
  end if;
  if v_pay.status <> 'pending' then
    raise exception 'This payment is already %', v_pay.status;
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason so the tenant knows what to fix';
  end if;
  update payments set status = 'rejected', status_reason = trim(p_reason) where id = p_payment_id;
end $$;

-- A confirmed payment entered by mistake: reverse it (never edit it). Charges it
-- had paid become unpaid again; other unused credit is applied automatically.
create or replace function rpc_reverse_payment(p_payment_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_pay payments%rowtype;
  v_pg  uuid;
begin
  select * into v_pay from payments where id = p_payment_id for update;
  select pg_id into v_pg from stays where id = v_pay.stay_id;
  if v_pay.id is null or not is_pg_staff(v_pg, array['owner', 'manager']) then
    raise exception 'You do not have access to this payment' using errcode = '42501';
  end if;
  if v_pay.status <> 'confirmed' then
    raise exception 'Only a confirmed payment can be reversed';
  end if;
  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Give a reason for reversing this payment';
  end if;
  update payments set status = 'reversed', status_reason = trim(p_reason) where id = p_payment_id;
  perform apply_stay_credit(v_pay.stay_id);
end $$;


-- ---------------------------------------------------------------------
-- Owner marks a guest as vacated. The stay is kept as history (the guest can
-- still read it); the bed is freed; reminders stop because the stay is no
-- longer open.
-- ---------------------------------------------------------------------
create or replace function rpc_vacate_stay(p_stay_id uuid, p_leave_date date default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_stay stays%rowtype;
  v_date date;
begin
  select * into v_stay from stays where id = p_stay_id for update;
  if v_stay.id is null or not is_pg_staff(v_stay.pg_id, array['owner', 'manager']) then
    raise exception 'You do not have access to this stay' using errcode = '42501';
  end if;
  if v_stay.status = 'vacated' then
    raise exception 'This guest has already vacated';
  end if;

  v_date := greatest(coalesce(p_leave_date, today_ist()), v_stay.join_date);

  update stays set status = 'vacated', leave_date = v_date where id = p_stay_id;
  update stay_bed_assignments set to_date = greatest(v_date, from_date)
   where stay_id = p_stay_id and to_date is null;
end $$;


-- ---------------------------------------------------------------------
-- Let signed-in users call the public functions (everything named rpc_*)
-- except the scheduler-only one. Helpers stay private.
-- ---------------------------------------------------------------------
do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname like 'rpc\_%'
      and p.proname <> 'rpc_generate_monthly_charges'
  loop
    execute format('grant execute on function %s to authenticated', f.sig);
  end loop;
end $$;
