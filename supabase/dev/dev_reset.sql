-- =====================================================================
--  DEV ONLY: wipe all test data
-- ---------------------------------------------------------------------
--  Deletes EVERYTHING people have entered: persons, PGs, rooms, guests,
--  charges, payments, receipts, notifications, the audit log, file records
--  and ALL logins. Keeps the reference data the app needs to work (roles,
--  payment methods, charge types, room types, amenities, document types,
--  relationship types, UPI apps, states, cities).
--
--  NEVER RUN THIS ON THE REAL (PRODUCTION) PROJECT.
--
--  How to run (Supabase SQL editor of the DEV project, one run, in this order):
--      set app.allow_reset = 'yes';
--      ...then the rest of this file.
--  Check the project name at the top of the dashboard first.
--  Uploaded images in Storage are not touched: empty those buckets by hand.
-- =====================================================================

-- One all-or-nothing block: if the confirmation is missing, NOTHING below runs,
-- whatever tool you use to execute this file.
do $$
begin
  if coalesce(current_setting('app.allow_reset', true), '') <> 'yes' then
    raise exception 'Reset not confirmed. Run  set app.allow_reset = ''yes'';  first, and only on the DEV project.';
  end if;

  truncate table
    audit_log, notifications, device_tokens, receipts, payment_allocations, payment_upi_details,
    payments, charges, stay_rent_terms, stay_bed_assignments, stays,
    room_amenities, beds, rooms, reminder_rules, pg_payment_accounts, pg_billing_settings,
    pg_members, pgs, addresses, emergency_contacts, person_documents, files, persons
  restart identity cascade;

  delete from auth.users;   -- removes every test login (Supabase)
end $$;
