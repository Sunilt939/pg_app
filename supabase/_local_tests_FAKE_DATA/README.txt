FAKE DATA WARNING
=================
Everything in this folder creates FAKE people, phone numbers, PGs and payments
(for example "Arjun Kumar" and "Sunrise PG"). These files are database checks that I
ran on a scratch PostgreSQL on my own machine. They are NOT part of your app.

* Do NOT run them in your Supabase project (dev or real). Not in the SQL editor either.
* They refuse to run unless you deliberately start psql with
      PGOPTIONS="-c app.allow_fake_data=yes"
  so they cannot run by accident.
* You do not need them to build or test the app. Ignore this folder.
* The real (and only) data your project gets is the reference data inside
  migrations/001_core_schema.sql (roles, payment methods, cities ...). That is not fake data.
