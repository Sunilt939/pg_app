-- =====================================================================
--  Scenario test for 001_core_schema.sql + 002_core_functions.sql
--  Written for plain PostgreSQL 15+ with the stand-in from tests_00_auth_stub.sql
--  (it imitates Supabase's auth schema and roles). Ask your AI tool to adapt
--  it to the Supabase CLI test setup; the SCENARIOS are what matter:
--    sign-in linking, who sees what, money maths, privacy after leaving,
--    and the things the database must refuse.
--  Run:  psql -d <database> -f tests_00_auth_stub.sql   (once)
--        psql -d <database> -f 001_core_schema.sql
--        psql -d <database> -f 002_core_functions.sql
--        psql -d <database> -f tests_10_scenario.sql
--  Lines that say "-- expect error" SHOULD print an ERROR. Anything else is a bug.
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

\echo '=== 1. two owners sign in (auth rows created; persons linked by trigger)'
insert into auth.users (id, phone) values (:'owner_a','919876500001'), (:'owner_b','919876500002');
select phone, auth_user_id is not null as linked from persons order by phone;

\echo '=== 2. owner A creates a PG, rooms, beds, a UPI account'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_create_pg('Sunrise PG','12 MG Road',(select id from cities where name='Bengaluru'),'560001','Indiranagar','98765 00001','men') as pg_a \gset
insert into rooms (pg_id, room_number, floor, room_type_id) values (:'pg_a','101',1,(select id from room_types where code='double'));
insert into beds (room_id, label) select id,'A' from rooms where pg_id = :'pg_a' and room_number='101';
insert into beds (room_id, label) select id,'B' from rooms where pg_id = :'pg_a' and room_number='101';
insert into pg_payment_accounts (pg_id, nickname, kind, upi_vpa, is_default) values (:'pg_a','SBI - Ramesh','upi','ramesh@sbi', true);
insert into pg_payment_accounts (pg_id, nickname, kind, upi_vpa) values (:'pg_a','HDFC - shop','upi','shop@hdfcbank');
select count(*) as rooms_seen from rooms;
select count(*) as beds_seen from beds;
reset role;
select id as bed_a from beds where label='A' limit 1 \gset
select id as bed_b from beds where label='B' limit 1 \gset
select id as acc_sbi from pg_payment_accounts where nickname='SBI - Ramesh' \gset
select id as acc_hdfc from pg_payment_accounts where nickname='HDFC - shop' \gset
select (today_ist() - 45) as join_date \gset

\echo '=== 3. owner A adds a guest BEFORE the guest has logged in (rent 6500, deposit 10000)'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_create_stay(:'pg_a','98765 00003','Arjun K',:'bed_a',:'join_date'::date,650000,1000000) as stay_a \gset
reset role;
select phone, full_name, auth_user_id as linked_before_login from persons where phone='+919876500003';

\echo '=== 4. guest logs in for the first time -> existing person is linked (not duplicated)'
insert into auth.users (id, phone) values (:'tenant','919876500003');
select phone, auth_user_id = :'tenant' as linked_now from persons where phone='+919876500003';
select count(*) as persons_with_this_phone from persons where phone='+919876500003';

\echo '=== 5. scheduler creates monthly rent charges (twice -> second run must create 0)'
select today_ist() as today, :'join_date'::date as join_date;
select rpc_generate_monthly_charges(date_trunc('month', :'join_date'::date)::date) as created_join_month;
select rpc_generate_monthly_charges(date_trunc('month', :'join_date'::date + interval '1 month')::date) as created_next_month;
select rpc_generate_monthly_charges(date_trunc('month', :'join_date'::date + interval '1 month')::date) as created_again_should_be_0;
select description, due_date, amount_paise/100 as rupees, status, paid_paise/100 as paid, outstanding_paise/100 as outstanding
  from v_charge_balances where stay_id = :'stay_a' order by due_date, description;

\echo '=== 6. owner A records CASH 12000 -> oldest charges paid first, partial on the third'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_record_payment(:'stay_a',1200000,'cash') as pay_cash \gset
select description, status, paid_paise/100 as paid, outstanding_paise/100 as outstanding
  from v_charge_balances where stay_id = :'stay_a' order by due_date, description;
reset role;

\echo '=== 7. guest sees own data, can edit only profile fields, cannot touch money'
set role authenticated;
select set_config('request.jwt.claim.sub', :'tenant', false);
select jsonb_pretty(rpc_my_context() - 'person') as context;
select stay_status, charged_paise/100 as charged, outstanding_paise/100 as outstanding, credit_paise/100 as credit, pending_verification_paise/100 as pending from v_stay_balances;
select count(*) as stays_visible from stays;
select count(*) as persons_visible from persons;
update persons set full_name = 'Arjun Kumar' where phone = '+919876500003';
select full_name as name_after_self_edit from persons where phone = '+919876500003';
\echo '-- expect permission denied x4:'
update persons set phone = '+919999999999' where phone = '+919876500003';
update stays set status = 'vacated';
insert into payments (stay_id, payment_method_id, amount_paise, paid_on, status) values (:'stay_a', 1, 100, current_date, 'confirmed');
update charges set amount_paise = 1;
select rpc_generate_monthly_charges();
reset role;

\echo '=== 8. guest reports a UPI payment with optional details -> pending; duplicate UTR blocked'
set role authenticated;
select set_config('request.jwt.claim.sub', :'tenant', false);
select nickname, upi_vpa from pg_payment_accounts order by nickname;
select rpc_report_payment(p_stay_id => :'stay_a', p_amount_paise => 250000, p_method_code => 'upi', p_account_id => :'acc_hdfc', p_payer_app_code => 'phonepe', p_payer_phone => '98765 00003', p_utr => 'utr123456789') as pay_upi \gset
\echo '-- expect: UTR already recorded (same UTR, different letter case)'
select rpc_report_payment(p_stay_id => :'stay_a', p_amount_paise => 250000, p_method_code => 'upi', p_utr => 'UTR123456789');
\echo '-- optional details really optional: report cash with nothing else'
select rpc_report_payment(:'stay_a', 100000, 'cash') as pay_cash_claim \gset
select count(*) as upi_detail_rows, bool_and(payer_phone = '+919876500003') as phone_normalised from payment_upi_details;
select stay_status, pending_verification_paise/100 as pending, outstanding_paise/100 as outstanding from v_stay_balances;
reset role;

\echo '=== 9. owner B (another PG) sees nothing of PG A and cannot act on it'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_b', false);
select count(*) as b_sees_pgs from pgs;
select count(*) as b_sees_stays from stays;
select count(*) as b_sees_persons from persons;
select count(*) as b_sees_payments from payments;
select count(*) as b_sees_rows_in_balance_view from v_stay_balances;
select rpc_confirm_payment(:'pay_upi');
select rpc_record_payment(:'stay_a',100,'cash');
reset role;

\echo '=== 10. owner A confirms the UPI payment and fixes the account it reached'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_confirm_payment(:'pay_upi', :'acc_sbi');
select method_code, account_nickname, month, payment_count, total_paise/100 as rupees from v_collections_by_account order by method_code;
select description, status, paid_paise/100 as paid, outstanding_paise/100 as outstanding
  from v_charge_balances where stay_id = :'stay_a' order by due_date, description;
select count(*) as receipts_made from receipts;
reset role;

\echo '=== 11. advance: owner records CASH 20000 -> credit remains; next month charge consumes it'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_record_payment(:'stay_a',2000000,'cash',null,null,'advance for 3 months') as pay_adv \gset
reset role;
select outstanding_paise/100 as outstanding, credit_paise/100 as credit from v_stay_balances where stay_id = :'stay_a';
select rpc_generate_monthly_charges(date_trunc('month', :'join_date'::date + interval '2 month')::date) as created_third_month;
select outstanding_paise/100 as outstanding, credit_paise/100 as credit_after_new_charge from v_stay_balances where stay_id = :'stay_a';

\echo '=== 12. mistaken payment: reverse it (not edit); charges reopen'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_reverse_payment(:'pay_adv','entered twice by mistake');
reset role;
select outstanding_paise/100 as outstanding, credit_paise/100 as credit from v_stay_balances where stay_id = :'stay_a';
\echo '-- expect errors: edit confirmed payment, reverse twice'
update payments set amount_paise = 1 where id = :'pay_cash';
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_reverse_payment(:'pay_adv','again');
reset role;

\echo '=== 13. owner dashboard view'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select period_month, tenants_billed, expected_paise/100 as expected, collected_paise/100 as collected, pending_paise/100 as pending, overdue_paise/100 as overdue from v_pg_monthly_summary order by period_month;
reset role;

\echo '=== 14. privacy: sensitive data visible to PG staff only while the guest lives there'
set role authenticated;
select set_config('request.jwt.claim.sub', :'tenant', false);
insert into emergency_contacts (person_id, name, phone, is_primary) select id,'Meera','+919800000001',true from persons where phone='+919876500003';
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select count(*) as owner_sees_emergency_contacts_while_staying from emergency_contacts;
reset role;

\echo '=== 15. owner A marks the guest as vacated'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_vacate_stay(:'stay_a');
select status, leave_date is not null as has_leave_date from stays;
select count(*) as owner_sees_emergency_contacts_after_leaving from emergency_contacts;
select count(*) as owner_still_sees_guest_name from persons where phone='+919876500003';
select count(*) as owner_still_sees_charges from charges;
reset role;
select count(*) as open_bed_assignments_for_stay from stay_bed_assignments where stay_id=:'stay_a' and to_date is null;
\echo '-- guest still sees history, but cannot report new payments:'
set role authenticated;
select set_config('request.jwt.claim.sub', :'tenant', false);
select count(*) as guest_sees_old_charges from charges;
select count(*) as guest_sees_old_payments from payments;
select rpc_report_payment(:'stay_a',100,'cash');
select count(*) as guest_sees_pg_accounts_after_leaving from pg_payment_accounts;
reset role;

\echo '=== 16. same person joins a NEW PG (owner B) -> second stay, history intact'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_b', false);
select rpc_create_pg('Lakeview PG','5 Lake Rd',(select id from cities where name='Bengaluru')) as pg_b \gset
reset role;
select (today_ist()) as today_date \gset
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_b', false);
insert into rooms (pg_id, room_number) values (:'pg_b','1');
insert into beds (room_id,label) select id,'1' from rooms where pg_id=:'pg_b';
reset role;
select id as bed_b1 from beds where room_id in (select id from rooms where pg_id=:'pg_b') \gset
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_b', false);
select rpc_create_stay(:'pg_b','+91 98765 00003',null,:'bed_b1',:'today_date'::date,800000,0) as stay_b \gset
reset role;
set role authenticated;
select set_config('request.jwt.claim.sub', :'tenant', false);
select pg_name, status from (select g.name as pg_name, s.status, s.join_date from stays s join pgs g on g.id=s.pg_id order by s.join_date) x;
select count(*) as persons_rows_for_phone from persons where phone='+919876500003';
reset role;

\echo '=== 17. database guards (as superuser, so only the triggers stand in the way)'
\echo '-- expect errors:'
delete from payments;
delete from charges;
delete from stays;
update audit_log set action='update' where id=1;
insert into payment_allocations (payment_id, charge_id, amount_paise) select :'pay_cash', charge_id, 99999999 from v_charge_balances where stay_id=:'stay_a' limit 1;
insert into stay_bed_assignments (stay_id, bed_id, from_date) values (:'stay_b', :'bed_b', current_date);
insert into payments (stay_id, payment_method_id, amount_paise, paid_on, received_account_id, status, confirmed_by, confirmed_at)
  select :'stay_b', 1, 100, current_date, :'acc_sbi', 'confirmed', id, now() from persons limit 1;

\echo '=== 18. anonymous (not logged in) role gets nothing'
set role anon;
select count(*) from persons;
select count(*) from roles;
reset role;

\echo '=== 19. audit trail captured the changes'
select table_name, action, count(*) from audit_log group by 1,2 order by 1,2;

\echo '=== 20. phone normalisation'
select p, normalize_phone(p) from (values ('98765 43210'),('+91 98765-43210'),('098765 43210'),('919876543210'),('+14155552671'),('12345'),(null),('abc')) v(p);

\echo '=== 21. an EXISTING tenant (joined 8 months ago, deposit already paid) is moved into the app'
set role authenticated;
select set_config('request.jwt.claim.sub', :'owner_a', false);
select rpc_create_stay(
  p_pg_id => :'pg_a', p_phone => '98765 00004', p_full_name => 'Divya S', p_bed_id => :'bed_b',
  p_join_date => (today_ist() - 240), p_monthly_rent_paise => 700000, p_deposit_paise => 1400000,
  p_billing_starts_on => date_trunc('month', today_ist())::date, p_deposit_already_paid => true) as stay_old \gset
reset role;
select rpc_generate_monthly_charges(date_trunc('month', today_ist() - 90)::date) as old_month_should_create_0;
select rpc_generate_monthly_charges(date_trunc('month', today_ist())::date)       as this_month;
select description, due_date, status, outstanding_paise/100 as outstanding from v_charge_balances where stay_id = :'stay_old' order by due_date;
select charged_paise/100 as charged, paid_against_charges_paise/100 as paid, outstanding_paise/100 as outstanding, credit_paise/100 as credit from v_stay_balances where stay_id = :'stay_old';
