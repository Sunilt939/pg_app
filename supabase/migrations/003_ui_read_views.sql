-- =====================================================================
--  PG Rent App  |  003_ui_read_views.sql
--  The READ side of the screens. Read-only views, no table changes.
-- ---------------------------------------------------------------------
--  Why: a screen should get everything it shows from ONE query, with names,
--  rooms and money figures already worked out by the database. That keeps
--  money and status rules in SQL (never in Dart) and keeps the screens simple.
--
--  Every view uses security_invoker, so row-level security of the person who
--  is asking still applies: an owner sees only their PGs, a guest sees only
--  their own stays.
--
--  Screen -> view
--    Owner home, guest list, guest detail header, guest home -> v_guest_list
--    Owner home tab counts and overdue total               -> v_pg_overview
--    Setup checklist on a new PG                           -> v_pg_setup_status
--    Payments tab, payment detail, guest history           -> v_payment_feed
--    Money received screen (total on top)                  -> v_collections_month_total
--    Receipt screen                                        -> v_receipt_detail
--    Rooms and beds, bed picker                            -> v_bed_occupancy
-- =====================================================================

-- Future tables and views start with NO access for the app. Each migration
-- grants exactly what it needs (see the end of this file).
alter default privileges in schema public revoke all on tables    from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;


-- ---------------------------------------------------------------------
-- Every bed with its room, and who sleeps there now (if anyone).
-- ---------------------------------------------------------------------
create or replace view v_bed_occupancy with (security_invoker = true) as
select
  b.id           as bed_id,
  b.label        as bed_label,
  b.is_active    as bed_is_active,
  r.id           as room_id,
  r.pg_id,
  r.room_number,
  r.floor,
  r.is_active    as room_is_active,
  rt.code        as room_type_code,
  rt.label       as room_type_label,
  a.stay_id,
  s.person_id    as occupant_person_id,
  per.full_name  as occupant_name,
  per.phone      as occupant_phone
from beds b
join rooms r                     on r.id  = b.room_id
left join room_types rt          on rt.id = r.room_type_id
left join stay_bed_assignments a on a.bed_id = b.id and a.to_date is null
left join stays s                on s.id  = a.stay_id
left join persons per            on per.id = s.person_id;


-- ---------------------------------------------------------------------
-- One row per stay with everything a list row or a header needs.
--   attention_state (one word, in this priority):
--     past     the stay has ended
--     pending  the guest reported a payment that waits for the owner
--     overdue  something is unpaid after its due date
--     due      something is unpaid but not late yet
--     paid     nothing is unpaid
--   due_now_paise   unpaid money whose due date is today or earlier
--   next_due_date   the next unpaid charge that is due later than today
--   next_due_paise  how much is unpaid on that date
--   paid_paise      confirmed money that has been used against charges
--   has_signed_in   false until the guest has logged in once (owner's "invited" hint)
--   monthly_rent_paise is null when the rent only starts in the future.
-- ---------------------------------------------------------------------
create or replace view v_guest_list with (security_invoker = true) as
select
  s.id                as stay_id,
  s.pg_id,
  g.name              as pg_name,
  g.contact_phone     as pg_contact_phone,
  s.person_id,
  p.full_name,
  p.phone,
  p.photo_file_id,
  (p.auth_user_id is not null) as has_signed_in,
  s.status            as stay_status,
  s.join_date,
  s.leave_date,
  s.billing_day,
  cur.bed_id,
  cur.bed_label,
  cur.room_id,
  cur.room_number,
  rent.monthly_rent_paise,
  coalesce(b.charged_paise, 0)              as charged_paise,
  coalesce(b.paid_against_charges_paise, 0) as paid_paise,
  coalesce(b.outstanding_paise, 0)          as outstanding_paise,
  coalesce(b.overdue_paise, 0)              as overdue_paise,
  coalesce(b.credit_paise, 0)               as credit_paise,
  coalesce(b.pending_verification_paise, 0) as pending_verification_paise,
  b.oldest_unpaid_due_date,
  pn.due_now_paise,
  pn.next_due_date,
  pn2.next_due_paise,
  case
    when s.status = 'vacated'                          then 'past'
    when coalesce(b.pending_verification_paise, 0) > 0 then 'pending'
    when coalesce(b.overdue_paise, 0) > 0              then 'overdue'
    when coalesce(b.outstanding_paise, 0) > 0          then 'due'
    else 'paid'
  end as attention_state
from stays s
join persons p on p.id = s.person_id
join pgs g     on g.id = s.pg_id
left join lateral (
  select a.bed_id, bd.label as bed_label, r.id as room_id, r.room_number
  from stay_bed_assignments a
  join beds bd on bd.id = a.bed_id
  join rooms r on r.id = bd.room_id
  where a.stay_id = s.id and a.to_date is null
) cur on true
left join lateral (
  select t.monthly_rent_paise
  from stay_rent_terms t
  where t.stay_id = s.id and t.effective_from <= today_ist()
  order by t.effective_from desc
  limit 1
) rent on true
left join v_stay_balances b on b.stay_id = s.id
left join lateral (
  select coalesce(sum(cb.outstanding_paise) filter (where cb.due_date <= today_ist()), 0)::bigint as due_now_paise,
         min(cb.due_date) filter (where cb.due_date > today_ist()) as next_due_date
  from v_charge_balances cb
  where cb.stay_id = s.id and cb.status in ('due', 'partial', 'overdue')
) pn on true
left join lateral (
  select coalesce(sum(cb.outstanding_paise), 0)::bigint as next_due_paise
  from v_charge_balances cb
  where cb.stay_id = s.id and cb.status in ('due', 'partial') and cb.due_date = pn.next_due_date
) pn2 on true;


-- ---------------------------------------------------------------------
-- Every payment with the guest, room, method, account and optional UPI
-- details already joined in. status: pending | confirmed | rejected | reversed.
-- receipt_id is null until the payment is confirmed.
-- ---------------------------------------------------------------------
create or replace view v_payment_feed with (security_invoker = true) as
select
  p.id                 as payment_id,
  p.stay_id,
  s.pg_id,
  s.person_id,
  per.full_name,
  per.phone,
  cur.room_number,
  cur.bed_label,
  p.amount_paise,
  p.paid_on,
  p.status,
  p.status_reason,
  p.note,
  pm.code              as method_code,
  pm.label             as method_label,
  p.received_account_id,
  acc.nickname         as account_nickname,
  ua.code              as payer_app_code,
  ua.label             as payer_app_label,
  ud.payer_phone,
  ud.utr,
  ud.screenshot_file_id,
  coalesce(p.created_by = s.person_id, false) as reported_by_guest,
  p.created_at,
  p.confirmed_at,
  rc.id                as receipt_id,
  rc.receipt_no
from payments p
join stays s                    on s.id   = p.stay_id
join persons per                on per.id = s.person_id
join payment_methods pm         on pm.id  = p.payment_method_id
left join pg_payment_accounts acc on acc.id = p.received_account_id
left join payment_upi_details ud  on ud.payment_id = p.id
left join upi_apps ua             on ua.id = ud.payer_app_id
left join receipts rc             on rc.payment_id = p.id
left join lateral (
  select r.room_number, bd.label as bed_label
  from stay_bed_assignments a
  join beds bd on bd.id = a.bed_id
  join rooms r on r.id = bd.room_id
  where a.stay_id = s.id
  order by a.from_date desc, a.created_at desc
  limit 1
) cur on true;


-- ---------------------------------------------------------------------
-- Everything the receipt screen prints, in one row.
--   allocations      what the payment paid for: [{description, amount_paise}]
--   unallocated_paise  part of the payment not yet used (advance credit)
-- ---------------------------------------------------------------------
create or replace view v_receipt_detail with (security_invoker = true) as
select
  rc.id             as receipt_id,
  rc.receipt_no,
  rc.issued_at,
  pf.payment_id,
  pf.stay_id,
  pf.pg_id,
  g.name            as pg_name,
  g.contact_phone   as pg_contact_phone,
  ad.line1          as pg_address_line1,
  ad.area           as pg_area,
  ci.name           as pg_city,
  pf.full_name      as guest_name,
  pf.phone          as guest_phone,
  pf.room_number,
  pf.bed_label,
  pf.amount_paise,
  pf.paid_on,
  pf.status,
  pf.status_reason,
  pf.method_code,
  pf.method_label,
  pf.payer_app_label,
  pf.utr,
  coalesce(al.allocations, '[]'::jsonb)             as allocations,
  pf.amount_paise - coalesce(al.allocated_paise, 0) as unallocated_paise
from receipts rc
join v_payment_feed pf on pf.payment_id = rc.payment_id
join pgs g             on g.id = pf.pg_id
left join addresses ad on ad.id = g.address_id
left join cities ci    on ci.id = ad.city_id
left join lateral (
  select jsonb_agg(
           jsonb_build_object('description', coalesce(c.description, ct.label),
                              'amount_paise', pa.amount_paise)
           order by c.due_date, c.created_at) as allocations,
         sum(pa.amount_paise)::bigint         as allocated_paise
  from payment_allocations pa
  join charges c        on c.id  = pa.charge_id
  join charge_types ct  on ct.id = c.charge_type_id
  where pa.payment_id = rc.payment_id and c.voided_at is null
) al on true;


-- ---------------------------------------------------------------------
-- Money received per PG per month (the total above the per-account list).
-- ---------------------------------------------------------------------
create or replace view v_collections_month_total with (security_invoker = true) as
select pg_id, month, sum(total_paise)::bigint as total_paise, sum(payment_count)::int as payment_count
from v_collections_by_account
group by pg_id, month;


-- ---------------------------------------------------------------------
-- One row per PG you can see: counts for the filter tabs, the overdue
-- total and the number of payments waiting for confirmation.
-- ---------------------------------------------------------------------
create or replace view v_pg_overview with (security_invoker = true) as
select
  g.id as pg_id,
  count(gl.stay_id) filter (where gl.stay_status <> 'vacated')::int as open_count,
  count(gl.stay_id) filter (where gl.stay_status <> 'vacated' and gl.overdue_paise > 0)::int as overdue_count,
  count(gl.stay_id) filter (where gl.stay_status <> 'vacated'
                              and gl.outstanding_paise > 0 and gl.overdue_paise = 0)::int as due_count,
  count(gl.stay_id) filter (where gl.stay_status <> 'vacated' and gl.outstanding_paise = 0)::int as paid_count,
  count(gl.stay_id) filter (where gl.stay_status = 'vacated')::int as past_count,
  coalesce(sum(gl.overdue_paise) filter (where gl.stay_status <> 'vacated'), 0)::bigint as overdue_total_paise,
  (select count(*) from payments p join stays s on s.id = p.stay_id
    where s.pg_id = g.id and p.status = 'pending')::int as pending_payment_count
from pgs g
left join v_guest_list gl on gl.pg_id = g.id
group by g.id;


-- ---------------------------------------------------------------------
-- The "set up your PG" checklist on a new PG.
-- ---------------------------------------------------------------------
create or replace view v_pg_setup_status with (security_invoker = true) as
select
  g.id as pg_id,
  (select count(*) from rooms r where r.pg_id = g.id and r.is_active)::int                      as rooms_count,
  (select count(*) from pg_payment_accounts a where a.pg_id = g.id and a.is_active)::int        as accounts_count,
  (select count(*) from stays s where s.pg_id = g.id)::int                                       as guests_count
from pgs g;


-- ---------------------------------------------------------------------
-- Privileges: read-only for signed-in users, nothing for anonymous.
-- ---------------------------------------------------------------------
revoke all on v_bed_occupancy, v_guest_list, v_payment_feed, v_receipt_detail,
              v_collections_month_total, v_pg_overview, v_pg_setup_status from anon, authenticated;
grant select on v_bed_occupancy, v_guest_list, v_payment_feed, v_receipt_detail,
                v_collections_month_total, v_pg_overview, v_pg_setup_status to authenticated;
