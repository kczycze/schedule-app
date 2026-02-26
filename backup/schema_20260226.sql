


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
    CONSTRAINT "phone_format_check" CHECK (("phone" ~ '^[0-9]{9}$'::"text"))
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."companies" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "owner_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "company_name_length_check" CHECK (("char_length"(TRIM(BOTH FROM "name")) >= 2)),
    CONSTRAINT "slug_format_check" CHECK ((("slug" ~ '^[a-z0-9-]+$'::"text") AND ("char_length"("slug") >= 2)))
);


ALTER TABLE "public"."companies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."services" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "company_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "duration_minutes" integer NOT NULL,
    "price" numeric(10,2),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."services" OWNER TO "postgres";


ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_owner_unique" UNIQUE ("owner_id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "unique_booking_slot" UNIQUE ("company_id", "booking_date", "start_time");



CREATE INDEX "idx_bookings_company" ON "public"."bookings" USING "btree" ("company_id");



CREATE INDEX "idx_bookings_date" ON "public"."bookings" USING "btree" ("booking_date");



CREATE INDEX "idx_companies_owner" ON "public"."companies" USING "btree" ("owner_id");



CREATE INDEX "idx_companies_slug" ON "public"."companies" USING "btree" ("slug");



CREATE INDEX "idx_services_company" ON "public"."services" USING "btree" ("company_id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."companies"
    ADD CONSTRAINT "companies_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."services"
    ADD CONSTRAINT "services_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE CASCADE;



ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."companies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner_insert_company" ON "public"."companies" FOR INSERT WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "owner_insert_services" ON "public"."services" FOR INSERT WITH CHECK (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_bookings" ON "public"."bookings" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_select_companies" ON "public"."companies" FOR SELECT USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "owner_select_services" ON "public"."services" FOR SELECT USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_update_booking" ON "public"."bookings" FOR UPDATE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "owner_update_company" ON "public"."companies" FOR UPDATE USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "owner_update_services" ON "public"."services" FOR UPDATE USING (("company_id" IN ( SELECT "companies"."id"
   FROM "public"."companies"
  WHERE ("companies"."owner_id" = "auth"."uid"()))));



CREATE POLICY "public_insert_booking" ON "public"."bookings" FOR INSERT WITH CHECK (true);



CREATE POLICY "public_read_companies" ON "public"."companies" FOR SELECT USING (true);



CREATE POLICY "public_read_services" ON "public"."services" FOR SELECT USING (true);



ALTER TABLE "public"."services" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";








































































































































































GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."companies" TO "anon";
GRANT ALL ON TABLE "public"."companies" TO "authenticated";
GRANT ALL ON TABLE "public"."companies" TO "service_role";



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































