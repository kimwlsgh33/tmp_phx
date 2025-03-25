--
-- PostgreSQL database dump
--

-- Dumped from database version 16.6 (Homebrew)
-- Dumped by pg_dump version 16.6 (Homebrew)

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

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: ensure_single_primary_account(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_single_primary_account() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- If we're setting this account as primary
  IF NEW.is_primary = true THEN
    -- Unset any existing primary accounts for this user
    UPDATE connected_accounts
    SET is_primary = false
    WHERE user_id = NEW.user_id
      AND id != NEW.id
      AND is_primary = true;
  END IF;
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: connected_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.connected_accounts (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    avatar_url character varying(255),
    provider character varying(255) NOT NULL,
    provider_id character varying(255),
    is_primary boolean DEFAULT false NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: connected_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.connected_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: connected_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.connected_accounts_id_seq OWNED BY public.connected_accounts.id;


--
-- Name: linked_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.linked_accounts (
    id bigint NOT NULL,
    primary_user_id bigint NOT NULL,
    linked_user_id bigint NOT NULL,
    name character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: linked_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.linked_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: linked_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.linked_accounts_id_seq OWNED BY public.linked_accounts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: social_media_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.social_media_tokens (
    id bigint NOT NULL,
    access_token bytea NOT NULL,
    refresh_token bytea,
    expires_at timestamp(0) without time zone,
    platform character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    metadata jsonb,
    last_used_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: social_media_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.social_media_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: social_media_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.social_media_tokens_id_seq OWNED BY public.social_media_tokens.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email public.citext NOT NULL,
    hashed_password character varying(255) NOT NULL,
    confirmed_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    provider character varying(255),
    provider_id character varying(255),
    avatar_url character varying(255),
    confirmation_code character varying(6)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_tokens_id_seq OWNED BY public.users_tokens.id;


--
-- Name: connected_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connected_accounts ALTER COLUMN id SET DEFAULT nextval('public.connected_accounts_id_seq'::regclass);


--
-- Name: linked_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_accounts ALTER COLUMN id SET DEFAULT nextval('public.linked_accounts_id_seq'::regclass);


--
-- Name: social_media_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_media_tokens ALTER COLUMN id SET DEFAULT nextval('public.social_media_tokens_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens ALTER COLUMN id SET DEFAULT nextval('public.users_tokens_id_seq'::regclass);


--
-- Name: connected_accounts connected_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connected_accounts
    ADD CONSTRAINT connected_accounts_pkey PRIMARY KEY (id);


--
-- Name: linked_accounts linked_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_accounts
    ADD CONSTRAINT linked_accounts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: social_media_tokens social_media_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_media_tokens
    ADD CONSTRAINT social_media_tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: connected_accounts_provider_provider_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX connected_accounts_provider_provider_id_index ON public.connected_accounts USING btree (provider, provider_id) WHERE (provider_id IS NOT NULL);


--
-- Name: connected_accounts_user_id_email_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX connected_accounts_user_id_email_provider_index ON public.connected_accounts USING btree (user_id, email, provider);


--
-- Name: connected_accounts_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX connected_accounts_user_id_index ON public.connected_accounts USING btree (user_id);


--
-- Name: connected_accounts_user_id_is_primary_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX connected_accounts_user_id_is_primary_index ON public.connected_accounts USING btree (user_id, is_primary);


--
-- Name: linked_accounts_linked_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX linked_accounts_linked_user_id_index ON public.linked_accounts USING btree (linked_user_id);


--
-- Name: linked_accounts_primary_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX linked_accounts_primary_user_id_index ON public.linked_accounts USING btree (primary_user_id);


--
-- Name: primary_linked_user_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX primary_linked_user_index ON public.linked_accounts USING btree (primary_user_id, linked_user_id);


--
-- Name: social_media_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX social_media_tokens_user_id_index ON public.social_media_tokens USING btree (user_id);


--
-- Name: social_media_tokens_user_id_platform_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX social_media_tokens_user_id_platform_index ON public.social_media_tokens USING btree (user_id, platform);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_provider_provider_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_provider_provider_id_index ON public.users USING btree (provider, provider_id);


--
-- Name: users_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tokens_context_token_index ON public.users_tokens USING btree (context, token);


--
-- Name: users_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_tokens_user_id_index ON public.users_tokens USING btree (user_id);


--
-- Name: connected_accounts ensure_single_primary_account_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ensure_single_primary_account_trigger BEFORE INSERT OR UPDATE ON public.connected_accounts FOR EACH ROW EXECUTE FUNCTION public.ensure_single_primary_account();


--
-- Name: connected_accounts connected_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.connected_accounts
    ADD CONSTRAINT connected_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: linked_accounts linked_accounts_linked_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_accounts
    ADD CONSTRAINT linked_accounts_linked_user_id_fkey FOREIGN KEY (linked_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: linked_accounts linked_accounts_primary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_accounts
    ADD CONSTRAINT linked_accounts_primary_user_id_fkey FOREIGN KEY (primary_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: social_media_tokens social_media_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.social_media_tokens
    ADD CONSTRAINT social_media_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20240530000000);
INSERT INTO public."schema_migrations" (version) VALUES (20241226072000);
INSERT INTO public."schema_migrations" (version) VALUES (20241227000001);
INSERT INTO public."schema_migrations" (version) VALUES (20250307233903);
INSERT INTO public."schema_migrations" (version) VALUES (20250319121217);
INSERT INTO public."schema_migrations" (version) VALUES (20250325211052);
INSERT INTO public."schema_migrations" (version) VALUES (20250401000001);
