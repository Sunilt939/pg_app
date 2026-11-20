-- =====================================================================
--  PG Rent App  |  005_room_layout.sql
--  One new door: add a whole layout (many floors, many rooms, a different
--  number of beds in each room) in ONE all-or-nothing step.
--
--  Run this ONCE in the Supabase SQL editor, AFTER 001 to 004.
--  It only ADDS a function. It does not change any table or any old function,
--  so rooms you have already added are safe.
--
--  The app builds the list (101, 102 ... 201, 202 ...). The database checks
--  every item again, so a bug in the app cannot create bad rooms.
--
--  p_rooms is a JSON list. Each item looks like:
--     {"number": "101", "floor": 1, "beds": 2}
--  "floor" may be left out. "number" is text (101, G1, 001 ...).
--  Beds are labelled A, B, C ... (up to 12), same as rpc_add_rooms.
--
--  Returns how many rooms were created.
--  If any room number already exists, or a number appears twice in the list,
--  nothing is created and the message names the number.
-- =====================================================================

create or replace function rpc_add_room_layout(
  p_pg_id  uuid,
  p_rooms  jsonb
) returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_item    jsonb;
  v_number  text;
  v_floor   smallint;
  v_beds    integer;
  v_room    uuid;
  v_b       integer;
  v_count   integer;
  v_seen    text[] := '{}';
begin
  if not is_pg_staff(p_pg_id, array['owner', 'manager']) then
    raise exception 'You do not have access to this PG' using errcode = '42501';
  end if;

  if p_rooms is null or jsonb_typeof(p_rooms) <> 'array' then
    raise exception 'Add at least one room';
  end if;
  v_count := jsonb_array_length(p_rooms);
  if v_count < 1 then
    raise exception 'Add at least one room';
  end if;
  if v_count > 500 then
    raise exception 'Add up to 500 rooms at a time';
  end if;

  for v_item in select value from jsonb_array_elements(p_rooms) loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'Every room needs a number and a bed count';
    end if;

    -- room number
    v_number := trim(coalesce(v_item ->> 'number', ''));
    if v_number = '' then
      raise exception 'Every room needs a number';
    end if;
    if length(v_number) > 20 then
      raise exception 'Room number % is too long (20 characters at most)', v_number;
    end if;

    -- beds: whole number 1 to 12
    if coalesce(v_item ->> 'beds', '') !~ '^[0-9]{1,2}$' then
      raise exception 'Room % needs a bed count from 1 to 12', v_number;
    end if;
    v_beds := (v_item ->> 'beds')::integer;
    if v_beds < 1 or v_beds > 12 then
      raise exception 'Room % needs a bed count from 1 to 12', v_number;
    end if;

    -- floor: optional whole number, -99 to 99
    v_floor := null;
    if v_item ->> 'floor' is not null then
      if (v_item ->> 'floor') !~ '^-?[0-9]{1,2}$' then
        raise exception 'Room % has a floor that is not a number', v_number;
      end if;
      v_floor := (v_item ->> 'floor')::smallint;
    end if;

    -- the same number twice in this list
    if lower(v_number) = any (v_seen) then
      raise exception 'Room % appears twice in the list', v_number;
    end if;
    v_seen := v_seen || lower(v_number);

    -- the number already exists in this PG (any case)
    if exists (select 1 from rooms
               where pg_id = p_pg_id and lower(room_number) = lower(v_number)) then
      raise exception 'Room % already exists in this PG', v_number;
    end if;

    insert into rooms (pg_id, room_number, floor)
    values (p_pg_id, v_number, v_floor)
    returning id into v_room;

    for v_b in 1 .. v_beds loop
      insert into beds (room_id, label) values (v_room, chr(64 + v_b));
    end loop;
  end loop;

  return v_count;
end $$;

-- Only signed-in users may call it (default privileges are locked: grant explicitly).
revoke execute on function rpc_add_room_layout(uuid, jsonb) from public, anon;
grant  execute on function rpc_add_room_layout(uuid, jsonb) to authenticated;
