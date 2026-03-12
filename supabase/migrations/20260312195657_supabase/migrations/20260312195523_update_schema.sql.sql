
  create table "public"."employee_services" (
    "employee_id" uuid not null,
    "service_id" uuid not null
      );


alter table "public"."employee_services" enable row level security;


  create table "public"."employees" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "company_id" uuid not null,
    "name" text not null,
    "email" text,
    "avatar_url" text,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."employees" enable row level security;

alter table "public"."bookings" add column "employee_id" uuid;

alter table "public"."bookings" add column "rejection_reason" text;

alter table "public"."companies" add column "booking_approval" text not null default 'auto'::text;

alter table "public"."companies" add column "booking_mode" text not null default 'company'::text;

CREATE UNIQUE INDEX employee_services_pkey ON public.employee_services USING btree (employee_id, service_id);

CREATE UNIQUE INDEX employees_pkey ON public.employees USING btree (id);

CREATE INDEX idx_bookings_employee ON public.bookings USING btree (employee_id);

CREATE INDEX idx_employee_services_service ON public.employee_services USING btree (service_id);

CREATE INDEX idx_employees_active ON public.employees USING btree (company_id, is_active);

CREATE INDEX idx_employees_company ON public.employees USING btree (company_id);

alter table "public"."employee_services" add constraint "employee_services_pkey" PRIMARY KEY using index "employee_services_pkey";

alter table "public"."employees" add constraint "employees_pkey" PRIMARY KEY using index "employees_pkey";

alter table "public"."bookings" add constraint "bookings_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE SET NULL not valid;

alter table "public"."bookings" validate constraint "bookings_employee_id_fkey";

alter table "public"."companies" add constraint "companies_booking_approval_check" CHECK ((booking_approval = ANY (ARRAY['auto'::text, 'manual'::text]))) not valid;

alter table "public"."companies" validate constraint "companies_booking_approval_check";

alter table "public"."companies" add constraint "companies_booking_mode_check" CHECK ((booking_mode = ANY (ARRAY['company'::text, 'employee'::text]))) not valid;

alter table "public"."companies" validate constraint "companies_booking_mode_check";

alter table "public"."employee_services" add constraint "employee_services_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE not valid;

alter table "public"."employee_services" validate constraint "employee_services_employee_id_fkey";

alter table "public"."employee_services" add constraint "employee_services_service_id_fkey" FOREIGN KEY (service_id) REFERENCES public.services(id) ON DELETE CASCADE not valid;

alter table "public"."employee_services" validate constraint "employee_services_service_id_fkey";

alter table "public"."employees" add constraint "employee_name_length_check" CHECK ((char_length(TRIM(BOTH FROM name)) >= 2)) not valid;

alter table "public"."employees" validate constraint "employee_name_length_check";

alter table "public"."employees" add constraint "employees_company_id_fkey" FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE not valid;

alter table "public"."employees" validate constraint "employees_company_id_fkey";

grant delete on table "public"."employee_services" to "anon";

grant insert on table "public"."employee_services" to "anon";

grant references on table "public"."employee_services" to "anon";

grant select on table "public"."employee_services" to "anon";

grant trigger on table "public"."employee_services" to "anon";

grant truncate on table "public"."employee_services" to "anon";

grant update on table "public"."employee_services" to "anon";

grant delete on table "public"."employee_services" to "authenticated";

grant insert on table "public"."employee_services" to "authenticated";

grant references on table "public"."employee_services" to "authenticated";

grant select on table "public"."employee_services" to "authenticated";

grant trigger on table "public"."employee_services" to "authenticated";

grant truncate on table "public"."employee_services" to "authenticated";

grant update on table "public"."employee_services" to "authenticated";

grant delete on table "public"."employee_services" to "service_role";

grant insert on table "public"."employee_services" to "service_role";

grant references on table "public"."employee_services" to "service_role";

grant select on table "public"."employee_services" to "service_role";

grant trigger on table "public"."employee_services" to "service_role";

grant truncate on table "public"."employee_services" to "service_role";

grant update on table "public"."employee_services" to "service_role";

grant delete on table "public"."employees" to "anon";

grant insert on table "public"."employees" to "anon";

grant references on table "public"."employees" to "anon";

grant select on table "public"."employees" to "anon";

grant trigger on table "public"."employees" to "anon";

grant truncate on table "public"."employees" to "anon";

grant update on table "public"."employees" to "anon";

grant delete on table "public"."employees" to "authenticated";

grant insert on table "public"."employees" to "authenticated";

grant references on table "public"."employees" to "authenticated";

grant select on table "public"."employees" to "authenticated";

grant trigger on table "public"."employees" to "authenticated";

grant truncate on table "public"."employees" to "authenticated";

grant update on table "public"."employees" to "authenticated";

grant delete on table "public"."employees" to "service_role";

grant insert on table "public"."employees" to "service_role";

grant references on table "public"."employees" to "service_role";

grant select on table "public"."employees" to "service_role";

grant trigger on table "public"."employees" to "service_role";

grant truncate on table "public"."employees" to "service_role";

grant update on table "public"."employees" to "service_role";


  create policy "owner_delete_employee_services"
  on "public"."employee_services"
  as permissive
  for delete
  to public
using ((employee_id IN ( SELECT e.id
   FROM (public.employees e
     JOIN public.companies c ON ((c.id = e.company_id)))
  WHERE (c.owner_id = auth.uid()))));



  create policy "owner_insert_employee_services"
  on "public"."employee_services"
  as permissive
  for insert
  to public
with check ((employee_id IN ( SELECT e.id
   FROM (public.employees e
     JOIN public.companies c ON ((c.id = e.company_id)))
  WHERE (c.owner_id = auth.uid()))));



  create policy "owner_select_employee_services"
  on "public"."employee_services"
  as permissive
  for select
  to public
using ((employee_id IN ( SELECT e.id
   FROM (public.employees e
     JOIN public.companies c ON ((c.id = e.company_id)))
  WHERE (c.owner_id = auth.uid()))));



  create policy "public_read_employee_services"
  on "public"."employee_services"
  as permissive
  for select
  to public
using (true);



  create policy "owner_delete_employees"
  on "public"."employees"
  as permissive
  for delete
  to public
using ((company_id IN ( SELECT companies.id
   FROM public.companies
  WHERE (companies.owner_id = auth.uid()))));



  create policy "owner_insert_employees"
  on "public"."employees"
  as permissive
  for insert
  to public
with check ((company_id IN ( SELECT companies.id
   FROM public.companies
  WHERE (companies.owner_id = auth.uid()))));



  create policy "owner_select_employees"
  on "public"."employees"
  as permissive
  for select
  to public
using ((company_id IN ( SELECT companies.id
   FROM public.companies
  WHERE (companies.owner_id = auth.uid()))));



  create policy "owner_update_employees"
  on "public"."employees"
  as permissive
  for update
  to public
using ((company_id IN ( SELECT companies.id
   FROM public.companies
  WHERE (companies.owner_id = auth.uid()))));



  create policy "public_read_employees"
  on "public"."employees"
  as permissive
  for select
  to public
using ((is_active = true));



