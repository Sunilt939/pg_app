-- =====================================================================
--  View tests for 003_ui_read_views.sql
--  Run AFTER tests_10_scenario.sql: it reads the data that scenario leaves
--  behind (two owners, a guest with two stays, payments in every status).
--  "permission denied" lines under V8 are expected. Anything else is a bug.
-- =====================================================================
-- SAFETY: this file creates FAKE people, phone numbers and logins.
-- It refuses to run unless psql is started with:  PGOPTIONS="-c app.allow_fake_data=yes"
-- NEVER run it on your Supabase project (dev or real). Scratch PostgreSQL on your own computer only.
\set ON_ERROR_STOP on
do $$
begin
  if coalesce(current_setting('app.allow_fake_data', true), '') <> 'yes' then
    raise exception 'STOP: this file creates FAKE people and logins. Run it only on a scratch PostgreSQL on your own computer, never on a Supabase project.';
  end if;
end $$;
\set ON_ERROR_STOP off
\pset pager off
\pset null '(null)'
\set owner_a '11111111-1111-1111-1111-111111111111'
\set owner_b '22222222-2222-2222-2222-222222222222'
\set tenant  '33333333-3333-3333-3333-333333333333'

\echo '=== V1. owner A: guest list (v_guest_list) for PG A'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select full_name, stay_status, room_number, bed_label, monthly_rent_paise/100 as rent, outstanding_paise/100 as outstanding, overdue_paise/100 as overdue,
       credit_paise/100 as credit, pending_verification_paise/100 as pending, due_now_paise/100 as due_now, next_due_date, next_due_paise/100 as next_due, attention_state
from v_guest_list order by stay_status, full_name;

\echo '=== V2. owner A: overview and setup status'
select open_count, overdue_count, due_count, paid_count, past_count, overdue_total_paise/100 as overdue_total, pending_payment_count from v_pg_overview;
select rooms_count, accounts_count, guests_count from v_pg_setup_status;

\echo '=== V3. owner A: payment feed'
select full_name, room_number, method_label, payer_app_label, utr, amount_paise/100 as rupees, status, account_nickname, reported_by_guest, receipt_no from v_payment_feed order by created_at;

\echo '=== V4. owner A: receipt detail (first confirmed payment)'
select receipt_no, pg_name, pg_address_line1, pg_area, pg_city, guest_name, room_number, bed_label, amount_paise/100 as rupees, method_label, status,
       allocations, unallocated_paise/100 as unallocated from v_receipt_detail order by receipt_no limit 2;

\echo '=== V4b. money received per month (total and per account)'
select month, payment_count, total_paise/100 as rupees from v_collections_month_total order by month;
\echo '=== V5. owner A: beds'
select room_number, bed_label, occupant_name, room_type_label from v_bed_occupancy order by room_number, bed_label;
reset role;

\echo '=== V6. owner B: sees only PG B (and none of PG A)'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_b', false) \g /dev/null
select (select count(*) from v_guest_list) as guests, (select count(*) from v_payment_feed) as payments, (select count(*) from v_receipt_detail) as receipts, (select count(*) from v_bed_occupancy) as beds, (select count(*) from v_pg_overview) as pgs;
select pg_name, full_name, stay_status, attention_state from v_guest_list;
reset role;

\echo '=== V7. the guest (two stays: vacated in PG A, active in PG B)'
set role authenticated; select set_config('request.jwt.claim.sub', :'tenant', false) \g /dev/null
select pg_name, stay_status, room_number, outstanding_paise/100 as outstanding, attention_state, pg_contact_phone from v_guest_list order by join_date;
select method_label, amount_paise/100 as rupees, status, receipt_no, account_nickname from v_payment_feed order by created_at;
select count(*) as receipts_visible from v_receipt_detail;
select count(*) as overview_rows_for_guest from v_pg_overview;
reset role;

\echo '=== V8. anonymous gets nothing (expect permission denied x2)'
set role anon;
select count(*) from v_guest_list;
select count(*) from v_receipt_detail;
reset role;
