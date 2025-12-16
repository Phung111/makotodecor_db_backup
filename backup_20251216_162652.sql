--
-- PostgreSQL database dump
--

\restrict 8QG1a845HpZkEH9F9S9BVULPzgCDTyaBs50CbcqitGhOUaNXPzdWXJmd5ce3Not

-- Dumped from database version 17.7 (178558d)
-- Dumped by pg_dump version 17.7 (Debian 17.7-3.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: neondb_owner
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO neondb_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: neondb_owner
--

COMMENT ON SCHEMA public IS '';


--
-- Name: category_status; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.category_status AS ENUM (
    'ACTIVE',
    'INACTIVE'
);


ALTER TYPE public.category_status OWNER TO neondb_owner;

--
-- Name: img_type_status; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.img_type_status AS ENUM (
    'ACTIVE',
    'INACTIVE'
);


ALTER TYPE public.img_type_status OWNER TO neondb_owner;

--
-- Name: order_status; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.order_status AS ENUM (
    'NEW',
    'DEPOSITED',
    'CANCELLED',
    'COMPLETED'
);


ALTER TYPE public.order_status OWNER TO neondb_owner;

--
-- Name: product_status; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.product_status AS ENUM (
    'ACTIVE',
    'INACTIVE',
    'OUT_OF_STOCK',
    'DISCONTINUED'
);


ALTER TYPE public.product_status OWNER TO neondb_owner;

--
-- Name: role; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.role AS ENUM (
    'USER',
    'STAFF',
    'ADMIN'
);


ALTER TYPE public.role OWNER TO neondb_owner;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.user_status AS ENUM (
    'ACTIVE',
    'INACTIVE'
);


ALTER TYPE public.user_status OWNER TO neondb_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_counts; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.access_counts (
    id bigint NOT NULL,
    count bigint NOT NULL
);


ALTER TABLE public.access_counts OWNER TO neondb_owner;

--
-- Name: access_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.access_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.access_counts_id_seq OWNER TO neondb_owner;

--
-- Name: access_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.access_counts_id_seq OWNED BY public.access_counts.id;


--
-- Name: cart_items; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.cart_items (
    id bigint NOT NULL,
    cart_id bigint NOT NULL,
    quantity bigint NOT NULL,
    price bigint NOT NULL,
    discount bigint NOT NULL,
    product_id bigint NOT NULL,
    size_id bigint,
    color_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.cart_items OWNER TO neondb_owner;

--
-- Name: cart_items_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.cart_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cart_items_id_seq OWNER TO neondb_owner;

--
-- Name: cart_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.cart_items_id_seq OWNED BY public.cart_items.id;


--
-- Name: carts; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.carts (
    id bigint NOT NULL,
    user_id bigint NOT NULL
);


ALTER TABLE public.carts OWNER TO neondb_owner;

--
-- Name: carts_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.carts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.carts_id_seq OWNER TO neondb_owner;

--
-- Name: carts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.carts_id_seq OWNED BY public.carts.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    status public.category_status DEFAULT 'ACTIVE'::public.category_status NOT NULL,
    img_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone,
    updated_by bigint
);


ALTER TABLE public.categories OWNER TO neondb_owner;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO neondb_owner;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: colors; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.colors (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    color character varying(255) NOT NULL,
    img_id bigint,
    product_id bigint NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.colors OWNER TO neondb_owner;

--
-- Name: colors_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.colors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.colors_id_seq OWNER TO neondb_owner;

--
-- Name: colors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.colors_id_seq OWNED BY public.colors.id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE public.flyway_schema_history OWNER TO neondb_owner;

--
-- Name: img_types; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.img_types (
    id bigint NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    status public.img_type_status DEFAULT 'ACTIVE'::public.img_type_status NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone,
    updated_by bigint
);


ALTER TABLE public.img_types OWNER TO neondb_owner;

--
-- Name: img_types_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.img_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.img_types_id_seq OWNER TO neondb_owner;

--
-- Name: img_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.img_types_id_seq OWNED BY public.img_types.id;


--
-- Name: imgs; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.imgs (
    id bigint NOT NULL,
    priority bigint NOT NULL,
    url character varying(255) NOT NULL,
    public_id character varying(255),
    title character varying(255),
    subtitle character varying(255),
    is_default boolean DEFAULT false,
    product_id bigint,
    img_type_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.imgs OWNER TO neondb_owner;

--
-- Name: imgs_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.imgs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.imgs_id_seq OWNER TO neondb_owner;

--
-- Name: imgs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.imgs_id_seq OWNED BY public.imgs.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.order_items (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    quantity bigint NOT NULL,
    price bigint NOT NULL,
    discount bigint NOT NULL,
    product_id bigint NOT NULL,
    color_name character varying(100),
    size_name character varying(50),
    size_price bigint
);


ALTER TABLE public.order_items OWNER TO neondb_owner;

--
-- Name: COLUMN order_items.color_name; Type: COMMENT; Schema: public; Owner: neondb_owner
--

COMMENT ON COLUMN public.order_items.color_name IS 'Color name at time of order (snapshot)';


--
-- Name: COLUMN order_items.size_name; Type: COMMENT; Schema: public; Owner: neondb_owner
--

COMMENT ON COLUMN public.order_items.size_name IS 'Size name at time of order (snapshot)';


--
-- Name: COLUMN order_items.size_price; Type: COMMENT; Schema: public; Owner: neondb_owner
--

COMMENT ON COLUMN public.order_items.size_price IS 'Size price at time of order (snapshot)';


--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO neondb_owner;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    code character varying(255) NOT NULL,
    user_id bigint NOT NULL,
    status public.order_status DEFAULT 'NEW'::public.order_status NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone,
    updated_by bigint
);


ALTER TABLE public.orders OWNER TO neondb_owner;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO neondb_owner;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    discount bigint NOT NULL,
    sold bigint NOT NULL,
    base_sold bigint NOT NULL,
    status public.product_status DEFAULT 'ACTIVE'::public.product_status NOT NULL,
    category_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    updated_by bigint
);


ALTER TABLE public.products OWNER TO neondb_owner;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO neondb_owner;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: sizes; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.sizes (
    id bigint NOT NULL,
    size character varying(255) NOT NULL,
    price bigint NOT NULL,
    product_id bigint NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.sizes OWNER TO neondb_owner;

--
-- Name: sizes_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.sizes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sizes_id_seq OWNER TO neondb_owner;

--
-- Name: sizes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.sizes_id_seq OWNED BY public.sizes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(255),
    status public.user_status DEFAULT 'ACTIVE'::public.user_status NOT NULL,
    role public.role DEFAULT 'USER'::public.role NOT NULL,
    cart_id bigint,
    order_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO neondb_owner;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO neondb_owner;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: access_counts id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.access_counts ALTER COLUMN id SET DEFAULT nextval('public.access_counts_id_seq'::regclass);


--
-- Name: cart_items id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cart_items ALTER COLUMN id SET DEFAULT nextval('public.cart_items_id_seq'::regclass);


--
-- Name: carts id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.carts ALTER COLUMN id SET DEFAULT nextval('public.carts_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: colors id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.colors ALTER COLUMN id SET DEFAULT nextval('public.colors_id_seq'::regclass);


--
-- Name: img_types id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.img_types ALTER COLUMN id SET DEFAULT nextval('public.img_types_id_seq'::regclass);


--
-- Name: imgs id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.imgs ALTER COLUMN id SET DEFAULT nextval('public.imgs_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: sizes id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.sizes ALTER COLUMN id SET DEFAULT nextval('public.sizes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: access_counts; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.access_counts (id, count) FROM stdin;
\.


--
-- Data for Name: cart_items; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.cart_items (id, cart_id, quantity, price, discount, product_id, size_id, color_id, created_at, updated_at) FROM stdin;
2	1	2	10000	20	2	3	\N	2025-12-16 08:02:49.673801+00	2025-12-16 08:39:56.895187+00
1	1	2	100000	10	1	1	1	2025-12-16 07:54:58.745483+00	2025-12-16 08:40:09.597286+00
\.


--
-- Data for Name: carts; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.carts (id, user_id) FROM stdin;
1	1
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.categories (id, code, name, status, img_id, created_at, updated_at, updated_by) FROM stdin;
1	REM	Rèm – Tranh Noren	ACTIVE	1	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
2	CO	Cờ – Nobori – Yatai	ACTIVE	2	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
3	THE_GO	Ema – Thẻ Gỗ – Bảng Tên	ACTIVE	3	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
4	IZAKAYA	Trang Trí Izakaya	ACTIVE	4	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
5	DECOR_TRADITIONAL	Decor Truyền Thống Nhật	ACTIVE	5	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
\.


--
-- Data for Name: colors; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.colors (id, name, color, img_id, product_id, is_active) FROM stdin;
1	Đen	#000000	7	1	t
2	Đỏ	#a72a2a	8	1	t
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	20250107	init base data	SQL	V20250107__init_base_data.sql	512169673	neondb_owner	2025-12-16 07:23:13.448466	10534	t
2	20251811	insert base data	SQL	V20251811__insert_base_data.sql	1728812420	neondb_owner	2025-12-16 07:23:27.243462	1660	t
\.


--
-- Data for Name: img_types; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.img_types (id, code, name, status, created_at, updated_at, updated_by) FROM stdin;
1	DEFAULT	Mặc định	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
2	OTHER	Khác	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
3	DETAIL	Chi tiết	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
4	COLOR	Màu sắc	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
\.


--
-- Data for Name: imgs; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.imgs (id, priority, url, public_id, title, subtitle, is_default, product_id, img_type_id, created_at, updated_at) FROM stdin;
1	1	https://example.com/images/rem-tranh-noren.jpg	rem-tranh-noren	Rèm – Tranh Noren	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
2	2	https://example.com/images/co-nobori-yatai.jpg	co-nobori-yatai	Cờ – Nobori – Yatai	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
3	3	https://example.com/images/ema-the-go-bang-ten.jpg	ema-the-go-bang-ten	Ema – Thẻ Gỗ – Bảng Tên	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
4	4	https://example.com/images/trang-tri-izakaya.jpg	trang-tri-izakaya	Trang Trí Izakaya	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
5	5	https://example.com/images/decor-truyen-thong-nhat.jpg	decor-truyen-thong-nhat	Decor Truyền Thống Nhật	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
7	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765871658/makotodecor/colors/cevjddntlgeqnl5rqe7t.png	makotodecor/colors/cevjddntlgeqnl5rqe7t	\N	\N	f	1	4	2025-12-16 07:54:28.090052+00	2025-12-16 07:54:28.090052+00
8	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765871663/makotodecor/colors/wprmpwdo0mdyzxquegqq.png	makotodecor/colors/wprmpwdo0mdyzxquegqq	\N	\N	f	1	4	2025-12-16 07:54:28.320999+00	2025-12-16 07:54:28.320999+00
9	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765871559/makotodecor/products/q2ydtyplb4zlf9sj46lw.png	makotodecor/products/q2ydtyplb4zlf9sj46lw	\N	\N	t	1	1	2025-12-16 07:54:29.029922+00	2025-12-16 07:54:29.029922+00
10	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765872087/makotodecor/products/woekvux1cb6ovmfsvquh.png	makotodecor/products/woekvux1cb6ovmfsvquh	\N	\N	t	2	1	2025-12-16 08:01:54.087497+00	2025-12-16 08:01:54.087497+00
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.order_items (id, order_id, quantity, price, discount, product_id, color_name, size_name, size_price) FROM stdin;
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.orders (id, code, user_id, status, created_at, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.products (id, name, description, discount, sold, base_sold, status, category_id, created_at, updated_at, updated_by) FROM stdin;
1	Sản phẩm 1	\N	10	0	1000	ACTIVE	1	2025-12-16 07:53:14.34911+00	2025-12-16 07:53:15.388218+00	\N
2	Sản phẩm 2	\N	20	0	1000	ACTIVE	2	2025-12-16 08:01:53.373472+00	2025-12-16 08:01:54.327389+00	\N
\.


--
-- Data for Name: sizes; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.sizes (id, size, price, product_id, is_active) FROM stdin;
1	L	100000	1	t
2	XL	200000	1	t
3	M	10000	2	t
4	L	20000	2	t
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.users (id, username, password, name, email, phone, status, role, cart_id, order_id, created_at, updated_at) FROM stdin;
1	phung	$2a$10$w3ggyRlslq2bL8fGxIlU6ehsA1NkUWy4jugdx2SgiE6A2ctUGwXcG	phung	admin@gmail.com	\N	ACTIVE	ADMIN	\N	\N	2025-12-16 07:25:25.747501+00	2025-12-16 07:25:25.747501+00
\.


--
-- Name: access_counts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.access_counts_id_seq', 1, false);


--
-- Name: cart_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.cart_items_id_seq', 2, true);


--
-- Name: carts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.carts_id_seq', 1, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.categories_id_seq', 5, true);


--
-- Name: colors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.colors_id_seq', 2, true);


--
-- Name: img_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.img_types_id_seq', 4, true);


--
-- Name: imgs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.imgs_id_seq', 10, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.order_items_id_seq', 1, false);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.orders_id_seq', 1, false);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.products_id_seq', 2, true);


--
-- Name: sizes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.sizes_id_seq', 4, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Name: access_counts access_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.access_counts
    ADD CONSTRAINT access_counts_pkey PRIMARY KEY (id);


--
-- Name: cart_items cart_items_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);


--
-- Name: carts carts_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT carts_pkey PRIMARY KEY (id);


--
-- Name: carts carts_user_id_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT carts_user_id_key UNIQUE (user_id);


--
-- Name: categories categories_code_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_code_key UNIQUE (code);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: colors colors_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.colors
    ADD CONSTRAINT colors_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: img_types img_types_code_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.img_types
    ADD CONSTRAINT img_types_code_key UNIQUE (code);


--
-- Name: img_types img_types_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.img_types
    ADD CONSTRAINT img_types_pkey PRIMARY KEY (id);


--
-- Name: imgs imgs_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.imgs
    ADD CONSTRAINT imgs_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_code_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_code_key UNIQUE (code);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: orders orders_user_id_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_key UNIQUE (user_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: sizes sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.sizes
    ADD CONSTRAINT sizes_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_imgs_img_type_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_imgs_img_type_id ON public.imgs USING btree (img_type_id);


--
-- Name: idx_imgs_img_type_product; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_imgs_img_type_product ON public.imgs USING btree (img_type_id, product_id);


--
-- Name: idx_imgs_product_id; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX idx_imgs_product_id ON public.imgs USING btree (product_id);


--
-- Name: cart_items fk_cart_items_cart; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id) REFERENCES public.carts(id);


--
-- Name: cart_items fk_cart_items_color; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_cart_items_color FOREIGN KEY (color_id) REFERENCES public.colors(id);


--
-- Name: cart_items fk_cart_items_product; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: cart_items fk_cart_items_size; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT fk_cart_items_size FOREIGN KEY (size_id) REFERENCES public.sizes(id);


--
-- Name: carts fk_carts_user; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.carts
    ADD CONSTRAINT fk_carts_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: categories fk_categories_img; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_categories_img FOREIGN KEY (img_id) REFERENCES public.imgs(id);


--
-- Name: colors fk_colors_img; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.colors
    ADD CONSTRAINT fk_colors_img FOREIGN KEY (img_id) REFERENCES public.imgs(id);


--
-- Name: colors fk_colors_product; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.colors
    ADD CONSTRAINT fk_colors_product FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: imgs fk_imgs_img_type; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.imgs
    ADD CONSTRAINT fk_imgs_img_type FOREIGN KEY (img_type_id) REFERENCES public.img_types(id);


--
-- Name: imgs fk_imgs_product; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.imgs
    ADD CONSTRAINT fk_imgs_product FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: order_items fk_order_items_order; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: order_items fk_order_items_product; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: orders fk_orders_user; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: products fk_products_category; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: sizes fk_sizes_product; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.sizes
    ADD CONSTRAINT fk_sizes_product FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: users fk_users_cart; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_cart FOREIGN KEY (cart_id) REFERENCES public.carts(id);


--
-- Name: users fk_users_order; Type: FK CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_order FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: neondb_owner
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict 8QG1a845HpZkEH9F9S9BVULPzgCDTyaBs50CbcqitGhOUaNXPzdWXJmd5ce3Not

