


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."availability_settings" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "working_days" integer[] DEFAULT '{1,2,3,4,5}'::integer[] NOT NULL,
    "work_start" time without time zone DEFAULT '09:00:00'::time without time zone NOT NULL,
    "work_end" time without time zone DEFAULT '17:00:00'::time without time zone NOT NULL,
    "slot_duration" integer DEFAULT 30 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."availability_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."blocked_periods" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "employee_id" "uuid",
    "starts_at" "date" NOT NULL,
    "ends_at" "date" NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_range" CHECK (("ends_at" >= "starts_at"))
);


ALTER TABLE "public"."blocked_periods" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "service_id" "uuid" NOT NULL,
    "booking_date" "date" NOT NULL,
    "start_time" time without time zone NOT NULL,
    "customer_name" "text" NOT NULL,
    "customer_email" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "phone" "text" NOT NULL,
    "employee_id" "uuid",
    "rejection_reason" "text",
    CONSTRAINT "phone_format_check" CHECK (("phone" ~ '^[0-9]{9}$'::"text"))
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."companies" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "owner_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "booking_mode" "text" DEFAULT 'company'::"text" NOT NULL,
    "booking_approval" "text" DEFAULT 'auto'::"text" NOT NULL,
    CONSTRAINT "companies_booking_approval_check" CHECK (("booking_approval" = ANY (ARRAY['auto'::"text", 'manual'::"text"]))),
    CONSTRAINT "companies_booking_mode_check" CHECK (("booking_mode" = ANY (ARRAY['company'::"text", 'employee'::"text"]))),
    CONSTRAINT "company_name_length_check" CHECK (("char_length"(TRIM(BOTH FROM "name")) >= 2)),
    CONSTRAINT "slug_format_check" CHECK ((("slug" ~ '^[a-z0-9-]+$'::"text") AND ("char_length"("slug") >= 2)))
);


ALTER TABLE "public"."companies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."employee_services" (
    "employee_id" "uuid" NOT NULL,
    "service_id" "uuid" NOT NULL
);


ALTER TABLE "public"."employee_services" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."employees" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "email" "text",
    "avatar_url" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "employee_name_length_check" CHECK (("char_length"(TRIM(BOTH FROM "name")) >= 2))
);


ALTER TABLE "public"."employees" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "duration_minutes" integer NOT NULL,
    "price" numeric(10,2),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."services" OWNER TO "postgres";


ALTER TABLE ONLY "public"."availability_settings"
    ADD CONSTRAINT "availability_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blocked_periods"
    ADD CONSTRAINT "blocked_periods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_owner_unique" UNIQUE ("owner_id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."employee_services"
    ADD CONSTRAINT "employee_services_pkey" PRIMARY KEY ("employee_id", "service_id");



ALTER TABLE ONLY "public"."employees"
    ADD CONSTRAINT "employees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "unique_booking_slot" UNIQUE ("company_id", "booking_date", "start_time");



CREATE INDEX "idx_availability_company" ON "public"."availability_settings" USING "btree" ("company_id");



CREATE INDEX "idx_blocked_periods_company" ON "public"."blocked_periods" USING "btree" ("company_id", "starts_at", "ends_at");



CREATE INDEX "idx_blocked_periods_employee" ON "public"."blocked_periods" USING "btree" ("employee_id", "starts_at", "ends_at");



CREATE INDEX "idx_bookings_company" ON "public"."bookings" USING "btree" ("company_id");



CREATE INDEX "idx_bookings_date" ON "public"."bookings" USING "btree" ("booking_date");



CREATE INDEX "idx_bookings_employee" ON "public"."bookings" USING "btree" ("employee_id");



CREATE INDEX "idx_companies_owner" ON "public"."companies" USING "btree" ("owner_id");



CREATE INDEX "idx_companies_slug" ON "public"."companies" USING "btree" ("slug");



CREATE INDEX "idx_employee_services_service" ON "public"."employee_services" USING "btree" ("service_id");



CREATE INDEX "idx_employees_active" ON "public"."employees" USING "btree" ("company_id", "is_active");



CREATE INDEX "idx_employees_company" ON "public"."employees" USING "btree" ("company_id");



CREATE INDEX "idx_services_company" ON "public"."services" USING "btree" ("company_id");



ALTER TABLE ONLY "public"."availability_settings"
    ADD CONSTRAINT "availability_settings_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_periods"
    ADD CONSTRAINT "blocked_periods_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_periods"
    ADD CONSTRAINT "blocked_periods_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."employee_services"
    ADD CONSTRAINT "employee_services_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."employees"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."employee_services"
    ADD CONSTRAINT "employee_services_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."employees"
    ADD CONSTRAINT "employees_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE "public"."availability_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."blocked_periods" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."employee_services" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."employees" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner_delete_blocked_periods" ON "public"."blocked_periods" FOR DELETE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_delete_employee_services" ON "public"."employee_services" FOR DELETE USING (("employee_id" IN ( SELECT "e"."id"
   FROM ("public"."employees" "e"
     JOIN "public"."companies" "c" ON (("c"."id" = "e"."company_id")))
  WHERE ("c"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_delete_employees" ON "public"."employees" FOR DELETE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_insert_availability" ON "public"."availability_settings" FOR INSERT WITH CHECK (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_insert_blocked_periods" ON "public"."blocked_periods" FOR INSERT WITH CHECK (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_insert_company" ON "public"."companies" FOR INSERT WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "owner_insert_employee_services" ON "public"."employee_services" FOR INSERT WITH CHECK (("employee_id" IN ( SELECT "e"."id"
   FROM ("public"."employees" "e"
     JOIN "public"."companies" "c" ON (("c"."id" = "e"."company_id")))
  WHERE ("c"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_insert_employees" ON "public"."employees" FOR INSERT WITH CHECK (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_insert_services" ON "public"."services" FOR INSERT WITH CHECK (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_availability" ON "public"."availability_settings" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_blocked_periods" ON "public"."blocked_periods" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_bookings" ON "public"."bookings" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_companies" ON "public"."companies" FOR SELECT USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "owner_select_employee_services" ON "public"."employee_services" FOR SELECT USING (("employee_id" IN ( SELECT "e"."id"
   FROM ("public"."employees" "e"
     JOIN "public"."companies" "c" ON (("c"."id" = "e"."company_id")))
  WHERE ("c"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_employees" ON "public"."employees" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_services" ON "public"."services" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_update_availability" ON "public"."availability_settings" FOR UPDATE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_update_booking" ON "public"."bookings" FOR UPDATE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_update_company" ON "public"."companies" FOR UPDATE USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "owner_update_employees" ON "public"."employees" FOR UPDATE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_update_services" ON "public"."services" FOR UPDATE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "public_insert_booking" ON "public"."bookings" FOR INSERT WITH CHECK (true);



CREATE POLICY "public_read_availability" ON "public"."availability_settings" FOR SELECT USING (true);



CREATE POLICY "public_read_blocked_periods" ON "public"."blocked_periods" FOR SELECT USING (true);



CREATE POLICY "public_read_companies" ON "public"."companies" FOR SELECT USING (true);



CREATE POLICY "public_read_employee_services" ON "public"."employee_services" FOR SELECT USING (true);



CREATE POLICY "public_read_employees" ON "public"."employees" FOR SELECT USING (("is_active" = true));



CREATE POLICY "public_read_services" ON "public"."services" FOR SELECT USING (true);



ALTER TABLE "public"."services" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";








































































































































































GRANT ALL ON TABLE "public"."availability_settings" TO "anon";
GRANT ALL ON TABLE "public"."availability_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."availability_settings" TO "service_role";



GRANT ALL ON TABLE "public"."blocked_periods" TO "anon";
GRANT ALL ON TABLE "public"."blocked_periods" TO "authenticated";
GRANT ALL ON TABLE "public"."blocked_periods" TO "service_role";



GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."companies" TO "anon";
GRANT ALL ON TABLE "public"."companies" TO "authenticated";
GRANT ALL ON TABLE "public"."companies" TO "service_role";



GRANT ALL ON TABLE "public"."employee_services" TO "anon";
GRANT ALL ON TABLE "public"."employee_services" TO "authenticated";
GRANT ALL ON TABLE "public"."employee_services" TO "service_role";



GRANT ALL ON TABLE "public"."employees" TO "anon";
GRANT ALL ON TABLE "public"."employees" TO "authenticated";
GRANT ALL ON TABLE "public"."employees" TO "service_role";



GRANT ALL ON TABLE "public"."services" TO "anon";
GRANT ALL ON TABLE "public"."services" TO "authenticated";
GRANT ALL ON TABLE "public"."services" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































