--
-- PostgreSQL database dump (Data Only - Ordered by Dependencies)
-- Dumped from database version 17.7 (178558d)
-- Dumped by pg_dump version 17.7 (Debian 17.7-3.pgdg13+1)
-- Tables are ordered to respect foreign key constraints

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
-- 1. Data for Name: access_counts; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.access_counts (id, count) FROM stdin;
\.


--
-- 2. Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	20250107	init base data	SQL	V20250107__init_base_data.sql	512169673	neondb_owner	2025-12-16 07:23:13.448466	10534	t
2	20251811	insert base data	SQL	V20251811__insert_base_data.sql	1728812420	neondb_owner	2025-12-16 07:23:27.243462	1660	t
\.


--
-- 3. Data for Name: img_types; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.img_types (id, code, name, status, created_at, updated_at, updated_by) FROM stdin;
1	DEFAULT	Mặc định	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
2	OTHER	Khác	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
3	DETAIL	Chi tiết	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
4	COLOR	Màu sắc	ACTIVE	2025-12-16 07:23:28.236376+00	\N	\N
\.


--
-- 4. Data for Name: users; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.users (id, username, password, name, email, phone, status, role, cart_id, order_id, created_at, updated_at) FROM stdin;
1	phung	$2a$10$w3ggyRlslq2bL8fGxIlU6ehsA1NkUWy4jugdx2SgiE6A2ctUGwXcG	phung	admin@gmail.com	\N	ACTIVE	ADMIN	\N	\N	2025-12-16 07:25:25.747501+00	2025-12-16 07:25:25.747501+00
\.


--
-- 5. Data for Name: imgs; Type: TABLE DATA; Schema: public; Owner: neondb_owner
-- Note: product_id set to NULL initially to avoid circular reference, will be updated later
--

COPY public.imgs (id, priority, url, public_id, title, subtitle, is_default, product_id, img_type_id, created_at, updated_at) FROM stdin;
1	1	https://example.com/images/rem-tranh-noren.jpg	rem-tranh-noren	Rèm – Tranh Noren	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
2	2	https://example.com/images/co-nobori-yatai.jpg	co-nobori-yatai	Cờ – Nobori – Yatai	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
3	3	https://example.com/images/ema-the-go-bang-ten.jpg	ema-the-go-bang-ten	Ema – Thẻ Gỗ – Bảng Tên	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
4	4	https://example.com/images/trang-tri-izakaya.jpg	trang-tri-izakaya	Trang Trí Izakaya	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
5	5	https://example.com/images/decor-truyen-thong-nhat.jpg	decor-truyen-thong-nhat	Decor Truyền Thống Nhật	Category image	t	\N	1	2025-12-16 07:23:28.236376+00	\N
7	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765871658/makotodecor/colors/cevjddntlgeqnl5rqe7t.png	makotodecor/colors/cevjddntlgeqnl5rqe7t	\N	\N	f	\N	4	2025-12-16 07:54:28.090052+00	2025-12-16 07:54:28.090052+00
8	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765871663/makotodecor/colors/wprmpwdo0mdyzxquegqq.png	makotodecor/colors/wprmpwdo0mdyzxquegqq	\N	\N	f	\N	4	2025-12-16 07:54:28.320999+00	2025-12-16 07:54:28.320999+00
9	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765871559/makotodecor/products/q2ydtyplb4zlf9sj46lw.png	makotodecor/products/q2ydtyplb4zlf9sj46lw	\N	\N	t	\N	1	2025-12-16 07:54:29.029922+00	2025-12-16 07:54:29.029922+00
10	0	https://res.cloudinary.com/cloudinarymen/image/upload/v1765872087/makotodecor/products/woekvux1cb6ovmfsvquh.png	makotodecor/products/woekvux1cb6ovmfsvquh	\N	\N	t	\N	1	2025-12-16 08:01:54.087497+00	2025-12-16 08:01:54.087497+00
\.


--
-- 6. Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.categories (id, code, name, status, img_id, created_at, updated_at, updated_by) FROM stdin;
1	REM	Rèm – Tranh Noren	ACTIVE	1	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
2	CO	Cờ – Nobori – Yatai	ACTIVE	2	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
3	THE_GO	Ema – Thẻ Gỗ – Bảng Tên	ACTIVE	3	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
4	IZAKAYA	Trang Trí Izakaya	ACTIVE	4	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
5	DECOR_TRADITIONAL	Decor Truyền Thống Nhật	ACTIVE	5	2025-12-16 07:23:28.236376+00	2025-12-16 07:23:28.236376+00	\N
\.


--
-- 7. Data for Name: products; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.products (id, name, description, discount, sold, base_sold, status, category_id, created_at, updated_at, updated_by) FROM stdin;
1	Sản phẩm 1	\N	10	0	1000	ACTIVE	1	2025-12-16 07:53:14.34911+00	2025-12-16 07:53:15.388218+00	\N
2	Sản phẩm 2	\N	20	0	1000	ACTIVE	2	2025-12-16 08:01:53.373472+00	2025-12-16 08:01:54.327389+00	\N
\.


--
-- 7.1 Update imgs.product_id now that products exist (resolve circular reference)
--

UPDATE public.imgs SET product_id = 1 WHERE id IN (7, 8, 9);
UPDATE public.imgs SET product_id = 2 WHERE id = 10;


--
-- 8. Data for Name: sizes; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.sizes (id, size, price, product_id, is_active) FROM stdin;
1	L	100000	1	t
2	XL	200000	1	t
3	M	10000	2	t
4	L	20000	2	t
\.


--
-- 9. Data for Name: colors; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.colors (id, name, color, img_id, product_id, is_active) FROM stdin;
1	Đen	#000000	7	1	t
2	Đỏ	#a72a2a	8	1	t
\.


--
-- 10. Data for Name: carts; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.carts (id, user_id) FROM stdin;
1	1
\.


--
-- 11. Data for Name: cart_items; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.cart_items (id, cart_id, quantity, price, discount, product_id, size_id, color_id, created_at, updated_at) FROM stdin;
2	1	2	10000	20	2	3	\N	2025-12-16 08:02:49.673801+00	2025-12-16 08:39:56.895187+00
1	1	2	100000	10	1	1	1	2025-12-16 07:54:58.745483+00	2025-12-16 08:40:09.597286+00
\.


--
-- 12. Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.orders (id, code, user_id, status, created_at, updated_at, updated_by) FROM stdin;
\.


--
-- 13. Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.order_items (id, order_id, quantity, price, discount, product_id, color_name, size_name, size_price) FROM stdin;
\.


--
-- Sequence resets
--

SELECT pg_catalog.setval('public.access_counts_id_seq', 1, false);
SELECT pg_catalog.setval('public.cart_items_id_seq', 2, true);
SELECT pg_catalog.setval('public.carts_id_seq', 1, true);
SELECT pg_catalog.setval('public.categories_id_seq', 5, true);
SELECT pg_catalog.setval('public.colors_id_seq', 2, true);
SELECT pg_catalog.setval('public.img_types_id_seq', 4, true);
SELECT pg_catalog.setval('public.imgs_id_seq', 10, true);
SELECT pg_catalog.setval('public.order_items_id_seq', 1, false);
SELECT pg_catalog.setval('public.orders_id_seq', 1, false);
SELECT pg_catalog.setval('public.products_id_seq', 2, true);
SELECT pg_catalog.setval('public.sizes_id_seq', 4, true);
SELECT pg_catalog.setval('public.users_id_seq', 1, true);

--
-- PostgreSQL database dump complete (ordered by dependencies)
--
