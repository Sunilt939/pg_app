-- =====================================================================
--  Tests for 004_ui_write_functions.sql
--  Run AFTER tests_10_scenario.sql (it needs the PGs and people that scenario
--  creates). Every line printed as ERROR below a "-- expect" comment is correct.
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
select id as pg_a from pgs where name = 'Sunrise PG' \gset
select id as pg_b from pgs where name = 'Lakeview PG' \gset

\echo '=== F1. owner A bulk-adds 3 rooms (G201..G203, 3 beds each, 3 sharing, floor 2)'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select rpc_add_rooms(:'pg_a', 201, 3, 3, 'triple', 2::smallint, 'G') as rooms_created;
select room_number, floor, room_type_label, string_agg(bed_label, ',' order by bed_label) as beds from v_bed_occupancy where room_number like 'G%' group by 1,2,3 order by 1;
\echo '-- expect errors: clash (nothing created), bad counts, unknown type'
select rpc_add_rooms(:'pg_a', 202, 3, 2, null, null, 'G');
select count(*) as rooms_still_only_three from rooms where room_number like 'G%';
select rpc_add_rooms(:'pg_a', 1, 0, 2);
select rpc_add_rooms(:'pg_a', 1, 5, 13);
select rpc_add_rooms(:'pg_a', 300, 1, 2, 'castle');
reset role;

\echo '=== F2. owner B and the guest cannot add rooms to PG A (expect 2 errors)'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_b', false) \g /dev/null
select rpc_add_rooms(:'pg_a', 900, 1, 1);
reset role;
set role authenticated; select set_config('request.jwt.claim.sub', :'tenant', false) \g /dev/null
select rpc_add_rooms(:'pg_a', 901, 1, 1);
reset role;

\echo '=== F3. correct a guest name before first login'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select rpc_create_stay(:'pg_a', '98765 00077', 'Rahull', null, today_ist(), 600000, 0) as stay_new \gset
select id as person_new from persons where phone = '+919876500077' \gset
select rpc_correct_guest_name(:'person_new', 'Rahul M');
select full_name as name_now from persons where id = :'person_new';
reset role;
\echo '-- after the guest signs in, the owner may no longer change it (expect error)'
insert into auth.users (id, phone) values ('77777777-7777-7777-7777-777777777777', '919876500077');
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select rpc_correct_guest_name(:'person_new', 'Someone Else');
\echo '-- another owner cannot rename a guest of PG A (expect error); blank name (expect error)'
reset role;
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_b', false) \g /dev/null
select rpc_correct_guest_name(:'person_new', 'Hacker');
reset role;
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select rpc_correct_guest_name(:'person_new', '   ');
reset role;
select full_name as name_unchanged from persons where id = :'person_new';

\echo '=== F4. guest attaches a screenshot to a reported UPI payment'
set role authenticated; select set_config('request.jwt.claim.sub', :'tenant', false) \g /dev/null
select s.id as stay_b from stays s join pgs g on g.id = s.pg_id where g.name = 'Lakeview PG' \gset
insert into files (bucket, object_path, mime_type, uploaded_by) select 'payment-screenshots', 'test/one.jpg', 'image/jpeg', id from persons where phone = '+919876500003' returning id as file_ok \gset
select rpc_report_payment(p_stay_id => :'stay_b', p_amount_paise => 100000, p_method_code => 'upi', p_utr => 'ZZ98765432', p_screenshot_file_id => :'file_ok') as pay_shot \gset
reset role;
select count(*) as upi_rows_with_screenshot from payment_upi_details where payment_id = :'pay_shot' and screenshot_file_id = :'file_ok';
\echo '-- owner B (staff of that PG) can read the screenshot record; owner A cannot (expect 1 then 0)'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_b', false) \g /dev/null
select count(*) as owner_b_sees_file from files where id = :'file_ok';
reset role;
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select count(*) as owner_a_sees_file from files where id = :'file_ok';
reset role;
\echo '-- a file uploaded by someone else cannot be attached (expect error)'
insert into files (bucket, object_path, mime_type, uploaded_by) select 'payment-screenshots', 'test/other.jpg', 'image/jpeg', id from persons where phone = '+919876500001' returning id as file_other \gset
set role authenticated; select set_config('request.jwt.claim.sub', :'tenant', false) \g /dev/null
select rpc_report_payment(p_stay_id => :'stay_b', p_amount_paise => 100, p_method_code => 'upi', p_screenshot_file_id => :'file_other');
reset role;

\echo '=== F5. owner A adds a layout with rpc_add_room_layout (005): 2 floors, different beds per room'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_a', false) \g /dev/null
select rpc_add_room_layout(:'pg_a', '[{"number":"L101","floor":1,"beds":2},{"number":"L102","floor":1,"beds":3},{"number":"L201","floor":2,"beds":1},{"number":"L202","floor":2,"beds":4}]'::jsonb) as rooms_created;
select room_number, floor, string_agg(bed_label, ',' order by bed_label) as beds from v_bed_occupancy where room_number like 'L%' group by 1,2 order by 1;
\echo '-- expect errors (each creates nothing): clash, same number twice, bad beds, empty list, bad floor, not a list'
select rpc_add_room_layout(:'pg_a', '[{"number":"L301","beds":2},{"number":"l101","beds":2}]'::jsonb);
select rpc_add_room_layout(:'pg_a', '[{"number":"L401","beds":2},{"number":"L401","beds":2}]'::jsonb);
select rpc_add_room_layout(:'pg_a', '[{"number":"L501","beds":13}]'::jsonb);
select rpc_add_room_layout(:'pg_a', '[]'::jsonb);
select rpc_add_room_layout(:'pg_a', '[{"number":"L601","floor":"x","beds":2}]'::jsonb);
select rpc_add_room_layout(:'pg_a', '{"number":"L701"}'::jsonb);
select count(*) as rooms_still_only_four from rooms where room_number like 'L%';
reset role;
\echo '-- owner B and the guest cannot add a layout to PG A (expect 2 errors)'
set role authenticated; select set_config('request.jwt.claim.sub', :'owner_b', false) \g /dev/null
select rpc_add_room_layout(:'pg_a', '[{"number":"X1","beds":1}]'::jsonb);
reset role;
set role authenticated; select set_config('request.jwt.claim.sub', :'tenant', false) \g /dev/null
select rpc_add_room_layout(:'pg_a', '[{"number":"X2","beds":1}]'::jsonb);
reset role;
