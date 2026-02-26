drop extension if exists "pg_net";

drop policy "owner_insert_company" on "public"."companies";

alter table "public"."bookings" add column "phone" text not null;

CREATE UNIQUE INDEX companies_owner_unique ON public.companies USING btree (owner_id);

CREATE UNIQUE INDEX unique_booking_slot ON public.bookings USING btree (company_id, booking_date, start_time);

alter table "public"."bookings" add constraint "phone_format_check" CHECK ((phone ~ '^[0-9]{9}$'::text)) not valid;

alter table "public"."bookings" validate constraint "phone_format_check";

alter table "public"."bookings" add constraint "unique_booking_slot" UNIQUE using index "unique_booking_slot";

alter table "public"."companies" add constraint "companies_owner_unique" UNIQUE using index "companies_owner_unique";

alter table "public"."companies" add constraint "company_name_length_check" CHECK ((char_length(TRIM(BOTH FROM name)) >= 2)) not valid;

alter table "public"."companies" validate constraint "company_name_length_check";

alter table "public"."companies" add constraint "slug_format_check" CHECK (((slug ~ '^[a-z0-9-]+$'::text) AND (char_length(slug) >= 2))) not valid;

alter table "public"."companies" validate constraint "slug_format_check";


  create policy "owner_insert_company"
  on "public"."companies"
  as permissive
  for insert
  to public
with check ((auth.uid() = owner_id));



