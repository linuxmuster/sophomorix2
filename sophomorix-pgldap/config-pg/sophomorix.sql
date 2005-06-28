--
-- PostgreSQL database dump
--

SET client_encoding = 'LATIN9';
SET check_function_bodies = false;

SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 4 (OID 2200)
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


SET SESSION AUTHORIZATION 'ldap';

SET search_path = public, pg_catalog;

--
-- TOC entry 5 (OID 71498)
-- Name: ldap_attr_mappings; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_attr_mappings (
    id serial NOT NULL,
    oc_map_id integer NOT NULL,
    name character varying(255) NOT NULL,
    sel_expr character varying(255) NOT NULL,
    sel_expr_u character varying(255),
    from_tbls character varying(255) NOT NULL,
    join_where character varying(255),
    add_proc character varying(255),
    delete_proc character varying(255),
    param_order integer NOT NULL,
    expect_return integer NOT NULL
);


--
-- TOC entry 6 (OID 71503)
-- Name: ldap_entries; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_entries (
    id serial NOT NULL,
    dn character varying(255) NOT NULL,
    oc_map_id integer NOT NULL,
    parent integer NOT NULL,
    keyval integer NOT NULL
);


--
-- TOC entry 7 (OID 71506)
-- Name: ldap_entry_objclasses; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_entry_objclasses (
    entry_id integer NOT NULL,
    oc_name character varying(64)
);


--
-- TOC entry 8 (OID 71510)
-- Name: institutes; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE institutes (
    id serial NOT NULL,
    name character varying(255)
);


--
-- TOC entry 9 (OID 71520)
-- Name: ldap_referrals; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_referrals (
    entry_id integer,
    name character(255),
    url character(255)
);


--
-- TOC entry 10 (OID 71524)
-- Name: groups_users; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups_users (
    gidnumber integer NOT NULL,
    memberuid integer NOT NULL
);


--
-- TOC entry 11 (OID 71526)
-- Name: groups_groups; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups_groups (
    gidnumber integer NOT NULL,
    membergid integer NOT NULL
);


--
-- TOC entry 49 (OID 71539)
-- Name: set_groups_cn(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_cn(character varying, integer) RETURNS integer
    AS 'UPDATE groups SET gid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 51 (OID 71540)
-- Name: set_groups_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_gidnumber(integer, integer) RETURNS integer
    AS 'UPDATE groups SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
UPDATE samba_group_mapping SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 50 (OID 71640)
-- Name: create_groups(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_groups() RETURNS integer
    AS 'SELECT setval (''groups_id_seq'', (select max(id) FROM groups));
INSERT INTO groups (id,gid,gidnumber) VALUES (nextval(''groups_id_seq''),'''',00);
INSERT INTO samba_group_mapping (id,gidnumber) VALUES ((SELECT max(id) FROM groups),00);
SELECT max(id) FROM groups
'
    LANGUAGE sql;


--
-- TOC entry 12 (OID 71654)
-- Name: samba_group_mapping; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE samba_group_mapping (
    id serial NOT NULL,
    gidnumber integer,
    sambasid character varying,
    sambagrouptype character varying,
    displayname character varying,
    description character varying,
    sambasidlist character varying
);


--
-- TOC entry 96 (OID 71680)
-- Name: set_groups_sambasid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambasid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_group_mapping SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES ((SELECT id from ldap_entries WHERE oc_map_id=4 AND keyval=$2),''sambaGroupMapping'');
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 99 (OID 71681)
-- Name: set_groups_sambagrouptype(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambagrouptype(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET sambagrouptype=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 100 (OID 71682)
-- Name: set_groups_sambasidlist(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambasidlist(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET sambasidlist=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 97 (OID 71683)
-- Name: set_groups_description(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_description(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET description=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 98 (OID 71684)
-- Name: set_groups_displayname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_displayname(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET displayname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 102 (OID 71727)
-- Name: create_account(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_account() RETURNS integer
    AS 'SELECT setval (''posix_account_id_seq'', (select case when max(id) is null then 1 else max(id) end from posix_account));
INSERT INTO posix_account (id,uidnumber,uid,gidnumber) VALUES (nextval(''posix_account_id_seq''),00,0,0);
INSERT INTO samba_sam_account (id) VALUES ((SELECT max(id) FROM posix_account));
SELECT max(id) FROM posix_account'
    LANGUAGE sql;


--
-- TOC entry 52 (OID 71730)
-- Name: set_account_uidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_uidnumber(integer, integer) RETURNS integer
    AS 'UPDATE posix_account SET uidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 53 (OID 71733)
-- Name: set_account_uid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_uid(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET uid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 54 (OID 71734)
-- Name: del_account_uid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_uid(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET uid=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 67 (OID 71735)
-- Name: set_account_surname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_surname(character varying, integer) RETURNS integer
    AS '        UPDATE posix_account SET surname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 55 (OID 71736)
-- Name: del_account_sn(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sn(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET surname=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 56 (OID 71737)
-- Name: set_account_firstname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_firstname(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET firstname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 57 (OID 71738)
-- Name: del_account_firstname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_firstname(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET firstname=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 58 (OID 71741)
-- Name: set_account_userpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_userpassword(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET userpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 59 (OID 71742)
-- Name: del_account_userpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_userpassword(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET userpassword=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 60 (OID 71743)
-- Name: set_account_loginshell(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_loginshell(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET loginshell=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 61 (OID 71744)
-- Name: del_account_loginshell(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_loginshell(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET loginshell=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 62 (OID 71745)
-- Name: del_account_uidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_uidnumber(integer, integer) RETURNS integer
    AS '
        UPDATE posix_account SET uidnumber=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 63 (OID 71746)
-- Name: set_account_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_gidnumber(integer, integer) RETURNS integer
    AS '
        UPDATE posix_account SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 64 (OID 71747)
-- Name: del_account_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_gidnumber(integer, integer) RETURNS integer
    AS '
        UPDATE posix_account SET gidnumber=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 65 (OID 71748)
-- Name: set_account_homedirectory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_homedirectory(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET homedirectory=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 66 (OID 71749)
-- Name: del_account_homedirectory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_homedirectory(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET homedirectory=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 13 (OID 71757)
-- Name: organizational_unit; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE organizational_unit (
    id serial NOT NULL,
    ou character varying(40) NOT NULL,
    description character varying(255)
);


--
-- TOC entry 68 (OID 71764)
-- Name: create_organizational_unit(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_organizational_unit() RETURNS integer
    AS '
	SELECT setval (''organizational_unit_id_seq'', (select max(id) FROM organizational_unit));
	INSERT INTO organizational_unit (id,ou,description) 
		VALUES (nextval(''organizational_unit_id_seq''),'''','''');
	SELECT max(id) FROM organizational_unit
'
    LANGUAGE sql;


--
-- TOC entry 69 (OID 71768)
-- Name: delete_organizational_unit(integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION delete_organizational_unit(integer) RETURNS integer
    AS '
	DELETE FROM organizational_unit WHERE id=CAST($1 AS INT);
	SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 70 (OID 71769)
-- Name: set_organizational_unit_ou(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_organizational_unit_ou(character varying, integer) RETURNS integer
    AS '
	UPDATE organizational_unit SET ou=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 71 (OID 71785)
-- Name: set_account_cn(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_cn(character varying, integer) RETURNS integer
    AS 'update posix_account set firstname = (
		select case 
			when position('' '' in $1) = 0 then $1 
			else substr($1, 1, position('' '' in $1) - 1)
		end
	),surname = (
		select case 
			when position('' '' in $1) = 0 then ''''
			else substr($1, position('' '' in $1) + 1) 
		end
	) where id = $2;
select $2 as return'
    LANGUAGE sql;


--
-- TOC entry 72 (OID 79716)
-- Name: set_account_sambasid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambasid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); 
INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES ((SELECT id from ldap_entries WHERE oc_map_id=3 AND keyval=$2),''sambaSamAccount'');
SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 73 (OID 79717)
-- Name: set_account_sambalmpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalmpassword(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalmpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 74 (OID 79718)
-- Name: set_account_sambantpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambantpassword(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambantpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 75 (OID 79719)
-- Name: set_account_sambapwdlastset(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdlastset(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdlastset=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 76 (OID 79720)
-- Name: set_account_sambalogontime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogontime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogontime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 77 (OID 79721)
-- Name: set_account_sambalogofftime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogofftime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogofftime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 78 (OID 79722)
-- Name: set_account_sambakickofftime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambakickofftime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambakickofftime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 79 (OID 79723)
-- Name: set_account_sambapwdcanchange(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdcanchange(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdcanchange=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 80 (OID 79724)
-- Name: set_account_sambapwdmustchange(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdmustchange(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdmustchange=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 81 (OID 79725)
-- Name: set_account_sambaacctflags(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaacctflags(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaacctflags=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 82 (OID 79726)
-- Name: set_account_displayname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_displayname(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET displayname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 83 (OID 79727)
-- Name: set_account_sambahomepath(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambahomepath(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomepath=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 84 (OID 79728)
-- Name: set_account_sambahomedrive(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambahomedrive(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomedrive=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 85 (OID 79729)
-- Name: set_account_sambalogonscript(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogonscript(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonscript=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 86 (OID 79730)
-- Name: set_account_sambaprofilepath(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaprofilepath(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprofilepath=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 87 (OID 79731)
-- Name: set_account_description(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_description(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET description=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 88 (OID 79732)
-- Name: set_account_sambauserworkstations(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambauserworkstations(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambauserworkstations=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 89 (OID 79733)
-- Name: set_account_sambaprimarygroupsid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaprimarygroupsid(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprimarygroupsid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 90 (OID 79734)
-- Name: set_account_sambadomainname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambadomainname(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambadomainname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 91 (OID 79736)
-- Name: set_account_sambabadpasswordcount(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambabadpasswordcount(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordcount=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 92 (OID 79737)
-- Name: set_account_sambabadpasswordtime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambabadpasswordtime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordtime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 93 (OID 79738)
-- Name: set_account_sambapasswordhistory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapasswordhistory(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapasswordhistory=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 94 (OID 79739)
-- Name: set_account_sambalogonhours(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogonhours(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonhours=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 95 (OID 79740)
-- Name: set_account_sambamungeddial(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambamungeddial(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambamungeddial=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 101 (OID 79865)
-- Name: character varying, integer(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION "character varying, integer"(integer, integer) RETURNS integer
    AS 'UPDATE posix_account SET gecos=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); 
SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 48 (OID 80040)
-- Name: set_account_gecos(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_gecos(character varying, integer) RETURNS integer
    AS 'UPDATE posix_account SET gecos=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 14 (OID 86325)
-- Name: groups; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups (
    id serial NOT NULL,
    gidnumber integer NOT NULL,
    gid character varying NOT NULL
);


--
-- TOC entry 15 (OID 86342)
-- Name: posix_account; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE posix_account (
    id serial NOT NULL,
    uidnumber integer NOT NULL,
    uid character varying(255) NOT NULL,
    gidnumber integer NOT NULL,
    firstname character varying(255),
    surname character varying(255),
    homedirectory character varying(255),
    gecos character varying(255),
    loginshell character varying(255),
    userpassword character varying(255),
    description character(255)
);


--
-- TOC entry 16 (OID 87151)
-- Name: samba_sam_account; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE samba_sam_account (
    id integer NOT NULL,
    sambasid character varying(255),
    cn character varying(255),
    sambalmpassword character varying(255),
    sambantpassword character varying(255),
    sambapwdlastset character varying(255),
    sambalogontime character varying(255),
    sambalogofftime character varying(255),
    sambakickofftime character varying(255),
    sambapwdcanchange character varying(255),
    sambapwdmustchange character varying(255),
    sambaacctflags character varying(255),
    displayname character varying(255),
    sambahomepath character varying(255),
    sambahomedrive character varying(255),
    sambalogonscript character varying(255),
    sambaprofilepath character varying(255),
    description character varying(255),
    sambauserworkstations character varying(255),
    sambaprimarygroupsid character varying(255),
    sambadomainname character varying(255),
    sambamungeddial character varying(255),
    sambabadpasswordcount character varying(255),
    sambabadpasswordtime character varying(255),
    sambapasswordhistory character varying(255),
    sambalogonhours character varying(255)
);


--
-- TOC entry 17 (OID 87943)
-- Name: ldap_oc_mappings; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_oc_mappings (
    id serial NOT NULL,
    name character varying(64) NOT NULL,
    keytbl character varying(64) NOT NULL,
    keycol character varying(64) NOT NULL,
    create_proc character varying(255),
    delete_proc character varying(255),
    expect_return integer NOT NULL
);


--
-- Data for TOC entry 103 (OID 71498)
-- Name: ldap_attr_mappings; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_attr_mappings VALUES (5, 1, 'o', 'institutes.name', NULL, 'institutes', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (7, 1, 'dc', 'lower(institutes.name)', NULL, 'institutes,ldap_entries AS dcObject,ldap_entry_objclasses as auxObjectClass', 'institutes.id=dcObject.keyval AND dcObject.oc_map_id=1 AND dcObject.id=auxObjectClass.entry_id AND auxObjectClass.oc_name=''dcObject''', NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (15, 4, 'memberUid', 'posix_account.uid', NULL, 'posix_account,groups_users,groups,groups_groups', 'groups_users.memberuid=posix_account.uidnumber AND ((groups_users.gidnumber=groups.gidnumber) OR (groups_groups.membergid=groups.gidnumber AND groups_groups.membergid=groups_users.gidnumber)) group by posix_account.uid', NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (14, 4, 'cn', 'groups.gid', NULL, 'groups', NULL, '{ call set_groups_cn(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (13, 4, 'gidNumber', 'groups.gidnumber', NULL, 'groups', NULL, '{ call set_groups_gidnumber(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (11, 3, 'homeDirectory', 'posix_account.homedirectory', NULL, 'posix_account', NULL, '{ call set_account_homedirectory(?,?) }', '{ call del_account_homedirectory(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (16, 3, 'loginShell', 'posix_account.loginshell', NULL, 'posix_account', NULL, '{ call set_account_loginshell(?,?) }', '{ call del_account_loginshell(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (10, 3, 'gidNumber', 'posix_account.gidnumber', NULL, 'posix_account', NULL, '{ call set_account_gidnumber(?,?) }', '{ call del_account_gidnumber(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (4, 3, 'userPassword', 'posix_account.userpassword', NULL, 'posix_account', NULL, '{ call set_account_userpassword(?,?) }', '{ call del_account_userpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (9, 3, 'uid', 'posix_account.uid', NULL, 'posix_account', NULL, '{ call set_account_uid(?,?) }', '{ call del_account_uid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (8, 2, 'ou', 'organizational_unit.ou', NULL, 'organizational_unit', NULL, '{ call set_organizational_unit_ou(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (12, 3, 'uidNumber', 'posix_account.uidnumber', NULL, 'posix_account', NULL, '{ call set_account_uidnumber(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (1, 3, 'cn', 'posix_account.firstname || '' '' || posix_account.surname', NULL, 'posix_account', NULL, '{ call set_account_cn(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (105, 3, 'sn', 'posix_account.surname', NULL, 'posix_account', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (106, 3, 'gn', 'posix_account.firstname', NULL, 'posix_account', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (95, 4, 'sambaSID', 'samba_group_mapping.sambasid', 'NULL', 'samba_group_mapping,groups', 'samba_group_mapping.gidnumber=groups.gidnumber', '{ call set_groups_sambasid(?,?) }', '', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (97, 4, 'displayName', 'samba_group_mapping.displayname', 'NULL', 'samba_group_mapping,groups', 'samba_group_mapping.gidnumber=groups.gidnumber', '{ call set_groups_displayname(?,?) }', '', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (96, 4, 'sambaGroupType', 'samba_group_mapping.sambagrouptype', 'NULL', 'samba_group_mapping,groups', 'samba_group_mapping.gidnumber=groups.gidnumber', '{ call set_groups_sambagrouptype(?,?) }', '', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (99, 4, 'sambaSIDList', 'samba_group_mapping.sambasidlist', 'NULL', 'samba_group_mapping,groups', 'samba_group_mapping.gidnumber=groups.gidnumber', '{ call set_groups_sambasidlist(?,?) }', '', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (98, 4, 'description', 'samba_group_mapping.description', 'NULL', 'samba_group_mapping,groups', 'samba_group_mapping.gidnumber=groups.gidnumber', '{ call set_groups_description(?,?) }', '', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (71, 3, 'sambaSID', 'samba_sam_account.sambasid', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambasid(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (72, 3, 'sambaLMPassword', 'samba_sam_account.sambalmpassword', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalmpassword(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (73, 3, 'sambaNTPassword', 'samba_sam_account.sambantpassword', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambantpassword(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (74, 3, 'sambaPwdLastSet', 'samba_sam_account.sambapwdlastset', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdlastset(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (75, 3, 'sambaLogonTime', 'samba_sam_account.sambalogontime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogontime(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (76, 3, 'sambaLogoffTime', 'samba_sam_account.sambalogofftime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogofftime(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (77, 3, 'sambaKickoffTime', 'samba_sam_account.sambakickofftime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambakickofftime(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (78, 3, 'sambaPwdCanChange', 'samba_sam_account.sambapwdcanchange', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdcanchange(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (79, 3, 'sambaPwdMustChange', 'samba_sam_account.sambapwdmustchange', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdmustchange(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (80, 3, 'sambaAcctFlags', 'samba_sam_account.sambaacctflags', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaacctflags(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (81, 3, 'displayName', 'samba_sam_account.displayname', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_displayname(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (82, 3, 'sambaHomePath', 'samba_sam_account.sambahomepath', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambahomepath(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (83, 3, 'sambaHomeDrive', 'samba_sam_account.sambahomedrive', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambahomedrive(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (84, 3, 'sambaLogonScript', 'samba_sam_account.sambalogonscript', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogonscript(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (85, 3, 'sambaProfilePath', 'samba_sam_account.sambaprofilepath', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaprofilepath(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (86, 3, 'description', 'samba_sam_account.description', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_description(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (87, 3, 'sambaUserWorkstations', 'samba_sam_account.sambauserworkstations', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambauserworkstations(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (88, 3, 'sambaPrimaryGroupSID', 'samba_sam_account.sambaprimarygroupsid', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaprimarygroupsid(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (89, 3, 'sambaDomainName', 'samba_sam_account.sambadomainname', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambadomainname(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (90, 3, 'sambaMungedDial', 'samba_sam_account.sambamungeddial', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambamungeddial(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (91, 3, 'sambaBadPasswordCount', 'samba_sam_account.sambabadpasswordcount', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambabadpasswordcount(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (92, 3, 'sambaBadPasswordTime', 'samba_sam_account.sambabadpasswordtime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambabadpasswordtime(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (93, 3, 'sambaPasswordHistory', 'samba_sam_account.sambapasswordhistory', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapasswordhistory(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (94, 3, 'sambaLogonHours', 'samba_sam_account.sambalogonhours', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogonhours(?,?) }', 'NULL', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (17, 3, 'gecos', 'posix_account.gecos', NULL, 'posix_account', NULL, '{ call set_account_gecos(?,?) }', NULL, 1, 0);


--
-- Data for TOC entry 104 (OID 71503)
-- Name: ldap_entries; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_entries VALUES (1, 'dc=linuxmuster,dc=de', 1, 0, 1);
INSERT INTO ldap_entries VALUES (5, 'ou=groups,dc=linuxmuster,dc=de', 2, 1, 5);
INSERT INTO ldap_entries VALUES (2, 'ou=accounts,dc=linuxmuster,dc=de', 2, 1, 1);


--
-- Data for TOC entry 105 (OID 71506)
-- Name: ldap_entry_objclasses; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_entry_objclasses VALUES (888, 'sambaGroupMapping');
INSERT INTO ldap_entry_objclasses VALUES (889, 'top');
INSERT INTO ldap_entry_objclasses VALUES (889, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (889, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (890, 'top');
INSERT INTO ldap_entry_objclasses VALUES (890, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (890, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (891, 'top');
INSERT INTO ldap_entry_objclasses VALUES (891, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (891, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (891, 'sambaSamAccount');


--
-- Data for TOC entry 106 (OID 71510)
-- Name: institutes; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO institutes VALUES (1, 'linuxmuster');


--
-- Data for TOC entry 107 (OID 71520)
-- Name: ldap_referrals; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_referrals VALUES (1, 'Referral                                                                                                                                                                                                                                                       ', 'ldap://localhost/                                                                                                                                                                                                                                              ');


--
-- Data for TOC entry 108 (OID 71524)
-- Name: groups_users; Type: TABLE DATA; Schema: public; Owner: ldap
--



--
-- Data for TOC entry 109 (OID 71526)
-- Name: groups_groups; Type: TABLE DATA; Schema: public; Owner: ldap
--



--
-- Data for TOC entry 110 (OID 71654)
-- Name: samba_group_mapping; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO samba_group_mapping VALUES (26, 1001, 'S-1-5-21-2023024621-2433660191-892785488-3003', '2', 'linuxmuster', NULL, NULL);


--
-- Data for TOC entry 111 (OID 71757)
-- Name: organizational_unit; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO organizational_unit VALUES (5, 'groups', 'Gruppen');
INSERT INTO organizational_unit VALUES (1, 'accounts', 'PosixAccounts');


--
-- Data for TOC entry 112 (OID 86325)
-- Name: groups; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO groups VALUES (26, 1001, 'linuxmuster');


--
-- Data for TOC entry 113 (OID 86342)
-- Name: posix_account; Type: TABLE DATA; Schema: public; Owner: ldap
--



--
-- Data for TOC entry 114 (OID 87151)
-- Name: samba_sam_account; Type: TABLE DATA; Schema: public; Owner: ldap
--



--
-- Data for TOC entry 115 (OID 87943)
-- Name: ldap_oc_mappings; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_oc_mappings VALUES (1, 'organization', 'institutes', 'id', NULL, NULL, 0);
INSERT INTO ldap_oc_mappings VALUES (4, 'posixGroup', 'groups', 'id', 'SELECT create_groups()', NULL, 0);
INSERT INTO ldap_oc_mappings VALUES (2, 'organizationalUnit', 'organizational_unit', 'id', 'SELECT create_organizational_unit()', 'SELECT delete_organizational_unit(?)', 0);
INSERT INTO ldap_oc_mappings VALUES (3, 'inetOrgPerson', 'posix_account', 'id', 'SELECT create_account()', NULL, 0);


--
-- TOC entry 30 (OID 85480)
-- Name: ldap_entries_ocmapid; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_ocmapid ON ldap_entries USING btree (oc_map_id);


--
-- TOC entry 32 (OID 85481)
-- Name: ldap_entry_objclasses_ocname; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entry_objclasses_ocname ON ldap_entry_objclasses USING btree (oc_name);


--
-- TOC entry 27 (OID 85482)
-- Name: ldap_entries_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_id ON ldap_entries USING btree (id);


--
-- TOC entry 29 (OID 85484)
-- Name: ldap_entries_keyval; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_keyval ON ldap_entries USING btree (keyval);


--
-- TOC entry 35 (OID 85491)
-- Name: samba_group_mapping_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX samba_group_mapping_id ON samba_group_mapping USING btree (id);


--
-- TOC entry 36 (OID 85500)
-- Name: samba_group_mapping_id_h; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX samba_group_mapping_id_h ON samba_group_mapping USING hash (id);


--
-- TOC entry 40 (OID 86338)
-- Name: groups_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX groups_id ON groups USING btree (id);


--
-- TOC entry 31 (OID 87940)
-- Name: ldap_entry_objclasses_entry_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entry_objclasses_entry_id ON ldap_entry_objclasses USING btree (entry_id);


--
-- TOC entry 43 (OID 101907)
-- Name: posix_account_id_uidnumber; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX posix_account_id_uidnumber ON posix_account USING btree (id, uidnumber);


--
-- TOC entry 26 (OID 101908)
-- Name: ldap_entries_dn; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_dn ON ldap_entries USING btree (dn);


--
-- TOC entry 37 (OID 101909)
-- Name: organizational_unit_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX organizational_unit_id ON organizational_unit USING btree (id);


--
-- TOC entry 33 (OID 101912)
-- Name: institutesid; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX institutesid ON institutes USING btree (id);


--
-- TOC entry 41 (OID 86331)
-- Name: groups_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_id_key UNIQUE (id);


--
-- TOC entry 39 (OID 86333)
-- Name: groups_gidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_gidnumber_key UNIQUE (gidnumber);


--
-- TOC entry 38 (OID 86335)
-- Name: groups_gid_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_gid_key UNIQUE (gid);


--
-- TOC entry 42 (OID 87129)
-- Name: posix_account_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_id_key UNIQUE (id);

ALTER TABLE posix_account CLUSTER ON posix_account_id_key;


--
-- TOC entry 45 (OID 87131)
-- Name: posix_account_uidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_uidnumber_key UNIQUE (uidnumber);


--
-- TOC entry 44 (OID 87133)
-- Name: posix_account_uid_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_uid_key UNIQUE (uid);


--
-- TOC entry 46 (OID 87156)
-- Name: samba_sam_account_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY samba_sam_account
    ADD CONSTRAINT samba_sam_account_id_key UNIQUE (id);


--
-- TOC entry 47 (OID 87946)
-- Name: ldap_oc_mappings_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY ldap_oc_mappings
    ADD CONSTRAINT ldap_oc_mappings_id_key UNIQUE (id);


--
-- TOC entry 28 (OID 101910)
-- Name: ldap_entries_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY ldap_entries
    ADD CONSTRAINT ldap_entries_id_key UNIQUE (id);


--
-- TOC entry 34 (OID 110105)
-- Name: samba_group_mapping_gidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY samba_group_mapping
    ADD CONSTRAINT samba_group_mapping_gidnumber_key UNIQUE (gidnumber, id);


--
-- TOC entry 18 (OID 71496)
-- Name: ldap_attr_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_attr_mappings_id_seq', 110, true);


--
-- TOC entry 19 (OID 71501)
-- Name: ldap_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_entries_id_seq', 891, true);


--
-- TOC entry 20 (OID 71508)
-- Name: institutes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('institutes_id_seq', 1, true);


--
-- TOC entry 21 (OID 71652)
-- Name: samba_group_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('samba_group_mapping_id_seq', 1, false);


--
-- TOC entry 22 (OID 71755)
-- Name: organizational_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('organizational_unit_id_seq', 6, true);


--
-- TOC entry 23 (OID 86323)
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('groups_id_seq', 26, true);


--
-- TOC entry 24 (OID 86340)
-- Name: posix_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('posix_account_id_seq', 4, true);


--
-- TOC entry 25 (OID 87941)
-- Name: ldap_oc_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_oc_mappings_id_seq', 8, true);


SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 3 (OID 2200)
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


