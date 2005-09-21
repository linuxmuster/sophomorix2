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
-- TOC entry 5 (OID 82398)
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
-- TOC entry 6 (OID 82403)
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
-- TOC entry 7 (OID 82406)
-- Name: ldap_entry_objclasses; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_entry_objclasses (
    entry_id integer NOT NULL,
    oc_name character varying(64)
);


--
-- TOC entry 8 (OID 82410)
-- Name: institutes; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE institutes (
    id serial NOT NULL,
    name character varying(255)
);


--
-- TOC entry 9 (OID 82413)
-- Name: ldap_referrals; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_referrals (
    entry_id integer,
    name character(255),
    url character(255)
);


--
-- TOC entry 10 (OID 82415)
-- Name: groups_users; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups_users (
    gidnumber integer NOT NULL,
    memberuid integer NOT NULL
);


--
-- TOC entry 11 (OID 82417)
-- Name: groups_groups; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups_groups (
    gidnumber integer NOT NULL,
    membergid integer NOT NULL
);


--
-- TOC entry 56 (OID 82419)
-- Name: set_groups_cn(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_cn(character varying, integer) RETURNS integer
    AS 'UPDATE groups SET gid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 57 (OID 82420)
-- Name: set_groups_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_gidnumber(integer, integer) RETURNS integer
    AS 'UPDATE groups SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
UPDATE samba_group_mapping SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 58 (OID 82421)
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
-- TOC entry 12 (OID 82424)
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
-- TOC entry 59 (OID 82430)
-- Name: set_groups_sambasid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambasid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_group_mapping SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES ((SELECT id from ldap_entries WHERE oc_map_id=4 AND keyval=$2),''sambaGroupMapping'');
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 60 (OID 82431)
-- Name: set_groups_sambagrouptype(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambagrouptype(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET sambagrouptype=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 61 (OID 82432)
-- Name: set_groups_sambasidlist(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambasidlist(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET sambasidlist=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 62 (OID 82433)
-- Name: set_groups_description(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_description(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET description=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 63 (OID 82434)
-- Name: set_groups_displayname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_displayname(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET displayname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 64 (OID 82435)
-- Name: create_account(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_account() RETURNS integer
    AS 'SELECT setval (''posix_account_id_seq'', (select case when max(id) is null then 1 else max(id) end from posix_account));
INSERT INTO posix_account (id,uidnumber,uid,gidnumber) VALUES (nextval(''posix_account_id_seq''),00,0,0);
INSERT INTO samba_sam_account (id) VALUES ((SELECT max(id) FROM posix_account));
SELECT max(id) FROM posix_account'
    LANGUAGE sql;


--
-- TOC entry 65 (OID 82436)
-- Name: set_account_uidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_uidnumber(integer, integer) RETURNS integer
    AS 'UPDATE posix_account SET uidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 66 (OID 82437)
-- Name: set_account_uid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_uid(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET uid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 67 (OID 82438)
-- Name: set_account_surname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_surname(character varying, integer) RETURNS integer
    AS '        UPDATE posix_account SET surname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 68 (OID 82439)
-- Name: set_account_firstname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_firstname(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET firstname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 69 (OID 82440)
-- Name: set_account_userpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_userpassword(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET userpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 70 (OID 82441)
-- Name: set_account_loginshell(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_loginshell(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET loginshell=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 71 (OID 82442)
-- Name: del_account_uidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_uidnumber(integer, integer) RETURNS integer
    AS '
        UPDATE posix_account SET uidnumber=NULL WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 72 (OID 82443)
-- Name: set_account_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_gidnumber(integer, integer) RETURNS integer
    AS '
        UPDATE posix_account SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 73 (OID 82444)
-- Name: del_account_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_gidnumber(integer, integer) RETURNS integer
    AS '        UPDATE posix_account SET gidnumber=1 WHERE id=CAST($1 AS INT);
        SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 74 (OID 82445)
-- Name: set_account_homedirectory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_homedirectory(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET homedirectory=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 13 (OID 82448)
-- Name: organizational_unit; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE organizational_unit (
    id serial NOT NULL,
    ou character varying(40) NOT NULL,
    description character varying(255)
);


--
-- TOC entry 75 (OID 82451)
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
-- TOC entry 76 (OID 82452)
-- Name: delete_organizational_unit(integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION delete_organizational_unit(integer) RETURNS integer
    AS '
	DELETE FROM organizational_unit WHERE id=CAST($1 AS INT);
	SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 77 (OID 82453)
-- Name: set_organizational_unit_ou(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_organizational_unit_ou(character varying, integer) RETURNS integer
    AS '
	UPDATE organizational_unit SET ou=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 78 (OID 82454)
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
-- TOC entry 79 (OID 82455)
-- Name: set_account_sambasid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambasid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); 
INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES ((SELECT id from ldap_entries WHERE oc_map_id=3 AND keyval=$2),''sambaSamAccount'');
SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 80 (OID 82456)
-- Name: set_account_sambalmpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalmpassword(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalmpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 81 (OID 82457)
-- Name: set_account_sambantpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambantpassword(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambantpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 82 (OID 82458)
-- Name: set_account_sambapwdlastset(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdlastset(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdlastset=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 83 (OID 82459)
-- Name: set_account_sambalogontime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogontime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogontime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 84 (OID 82460)
-- Name: set_account_sambalogofftime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogofftime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogofftime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 85 (OID 82461)
-- Name: set_account_sambakickofftime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambakickofftime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambakickofftime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 86 (OID 82462)
-- Name: set_account_sambapwdcanchange(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdcanchange(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdcanchange=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 87 (OID 82463)
-- Name: set_account_sambapwdmustchange(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdmustchange(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdmustchange=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 88 (OID 82464)
-- Name: set_account_sambaacctflags(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaacctflags(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaacctflags=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 89 (OID 82465)
-- Name: set_account_displayname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_displayname(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET displayname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 90 (OID 82466)
-- Name: set_account_sambahomepath(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambahomepath(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomepath=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 91 (OID 82467)
-- Name: set_account_sambahomedrive(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambahomedrive(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomedrive=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 92 (OID 82468)
-- Name: set_account_sambalogonscript(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogonscript(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonscript=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 93 (OID 82469)
-- Name: set_account_sambaprofilepath(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaprofilepath(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprofilepath=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 94 (OID 82470)
-- Name: set_account_description(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_description(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET description=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 95 (OID 82471)
-- Name: set_account_sambauserworkstations(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambauserworkstations(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambauserworkstations=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 96 (OID 82472)
-- Name: set_account_sambaprimarygroupsid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaprimarygroupsid(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprimarygroupsid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 97 (OID 82473)
-- Name: set_account_sambadomainname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambadomainname(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambadomainname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 98 (OID 82474)
-- Name: set_account_sambabadpasswordcount(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambabadpasswordcount(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordcount=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 99 (OID 82475)
-- Name: set_account_sambabadpasswordtime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambabadpasswordtime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordtime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 100 (OID 82476)
-- Name: set_account_sambapasswordhistory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapasswordhistory(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapasswordhistory=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 101 (OID 82477)
-- Name: set_account_sambalogonhours(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogonhours(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonhours=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 102 (OID 82478)
-- Name: set_account_sambamungeddial(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambamungeddial(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambamungeddial=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 103 (OID 82479)
-- Name: character varying, integer(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION "character varying, integer"(integer, integer) RETURNS integer
    AS 'UPDATE posix_account SET gecos=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); 
SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 104 (OID 82480)
-- Name: set_account_gecos(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_gecos(character varying, integer) RETURNS integer
    AS 'UPDATE posix_account SET gecos=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 14 (OID 82483)
-- Name: groups; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups (
    id serial NOT NULL,
    gidnumber integer NOT NULL,
    gid character varying NOT NULL
);


--
-- TOC entry 15 (OID 82491)
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
-- TOC entry 16 (OID 82497)
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
-- TOC entry 17 (OID 82504)
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
-- TOC entry 105 (OID 82507)
-- Name: del_account_userpassword(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_userpassword(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET userpassword=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 106 (OID 82508)
-- Name: del_account_sambantpassword(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambantpassword(integer, character varying) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambantpassword=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 107 (OID 82509)
-- Name: del_account_sambalmpassword(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalmpassword(integer, character varying) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambalmpassword=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 108 (OID 82510)
-- Name: del_account_sambapwdlastset(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapwdlastset(integer, character varying) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambapwdlastset=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 18 (OID 82511)
-- Name: posix_account_details; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE posix_account_details (
    id integer NOT NULL,
    schoolnumber character varying(255),
    unid character varying(255),
    birthname character varying(255),
    title character varying(255),
    gender character varying(255),
    birthday date,
    birthpostalcode character varying(255),
    birthcity character varying(255),
    denomination character varying(255),
    "class" integer,
    classentry integer,
    schooltype integer,
    chiefinstructor integer,
    nationality integer,
    religionparticipation boolean,
    ethicsparticipation boolean,
    education character varying(255),
    occupation character varying(255),
    starttraining date,
    endtraining date
);


--
-- TOC entry 19 (OID 82516)
-- Name: sambaunixidpool; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE sambaunixidpool (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- TOC entry 20 (OID 82523)
-- Name: sambadomain; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE sambadomain (
    id serial NOT NULL,
    sambadomainname character varying,
    sambasid character varying
);


--
-- TOC entry 109 (OID 82529)
-- Name: create_samba_domain(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_samba_domain() RETURNS integer
    AS 'INSERT INTO sambadomain (id,sambadomainname,sambasid) VALUES (nextval(''posix_account_id_seq''),0,0);
SELECT max(id) FROM sambadomain'
    LANGUAGE sql;


--
-- TOC entry 110 (OID 82530)
-- Name: set_samba_domain_name(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_samba_domain_name(character varying, integer) RETURNS integer
    AS 'UPDATE sambadomain SET sambadomainname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 111 (OID 82531)
-- Name: set_samba_domain_sid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_samba_domain_sid(character varying, integer) RETURNS integer
    AS 'UPDATE sambadomain SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 112 (OID 82532)
-- Name: del_account_sambasid(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambasid(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambasid=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 113 (OID 82533)
-- Name: del_account_sambalogontime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogontime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogontime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 114 (OID 82534)
-- Name: del_account_sambalogofftime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogofftime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogofftime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 115 (OID 82535)
-- Name: del_account_sambakickofftime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambakickofftime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambakickofftime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 116 (OID 82536)
-- Name: del_account_sambapwdcanchange(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapwdcanchange(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdcanchange=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 117 (OID 82537)
-- Name: del_account_sambapwdmustchange(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapwdmustchange(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdmustchange=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 118 (OID 82538)
-- Name: del_account_sambaacctflags(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambaacctflags(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaacctflags=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 119 (OID 82539)
-- Name: del_account_displayname(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_displayname(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET displayname=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 120 (OID 82540)
-- Name: del_account_sambahomepath(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambahomepath(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomepath=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 121 (OID 82541)
-- Name: del_account_sambahomedrive(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambahomedrive(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomedrive=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 122 (OID 82542)
-- Name: del_account_sambalogonscript(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogonscript(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonscript=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 123 (OID 82543)
-- Name: del_account_sambaprofilepath(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambaprofilepath(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprofilepath=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 124 (OID 82544)
-- Name: del_account_description(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_description(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET description=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 125 (OID 82545)
-- Name: del_account_sambauserworkstations(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambauserworkstations(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambauserworkstations=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 126 (OID 82546)
-- Name: del_account_sambaprimarygroupsid(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambaprimarygroupsid(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprimarygroupsid=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 127 (OID 82547)
-- Name: del_account_sambadomainname(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambadomainname(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambadomainname=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 128 (OID 82548)
-- Name: del_account_sambamungeddial(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambamungeddial(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambamungeddial=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 129 (OID 82549)
-- Name: del_account_sambabadpasswordcount(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambabadpasswordcount(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordcount=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 130 (OID 82550)
-- Name: del_account_sambabadpasswordtime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambabadpasswordtime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordtime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 131 (OID 82551)
-- Name: del_account_sambapasswordhistory(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapasswordhistory(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapasswordhistory=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 132 (OID 82552)
-- Name: del_account_sambalogonhours(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogonhours(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonhours=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 133 (OID 82553)
-- Name: delete_account(integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION delete_account(integer) RETURNS integer
    AS 'delete from posix_account where id=$1;
delete from samba_sam_account where id=$1;
SELECT max(id) FROM posix_account'
    LANGUAGE sql;


--
-- TOC entry 134 (OID 82554)
-- Name: del_account_uid(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_uid(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET uid=1 WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 135 (OID 82555)
-- Name: del_account_firstname(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_firstname(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET firstname=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 136 (OID 82556)
-- Name: del_account_homedirectory(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_homedirectory(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET homedirectory=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 137 (OID 82557)
-- Name: del_account_loginshell(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_loginshell(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET loginshell=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 138 (OID 82558)
-- Name: del_account_sn(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sn(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET surname=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- Data for TOC entry 139 (OID 82398)
-- Name: ldap_attr_mappings; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_attr_mappings VALUES (5, 1, 'o', 'institutes.name', NULL, 'institutes', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (7, 1, 'dc', 'lower(institutes.name)', NULL, 'institutes,ldap_entries AS dcObject,ldap_entry_objclasses as auxObjectClass', 'institutes.id=dcObject.keyval AND dcObject.oc_map_id=1 AND dcObject.id=auxObjectClass.entry_id AND auxObjectClass.oc_name=''dcObject''', NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (14, 4, 'cn', 'groups.gid', NULL, 'groups', NULL, '{ call set_groups_cn(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (13, 4, 'gidNumber', 'groups.gidnumber', NULL, 'groups', NULL, '{ call set_groups_gidnumber(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (11, 3, 'homeDirectory', 'posix_account.homedirectory', NULL, 'posix_account', NULL, '{ call set_account_homedirectory(?,?) }', '{ call del_account_homedirectory(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (16, 3, 'loginShell', 'posix_account.loginshell', NULL, 'posix_account', NULL, '{ call set_account_loginshell(?,?) }', '{ call del_account_loginshell(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (10, 3, 'gidNumber', 'posix_account.gidnumber', NULL, 'posix_account', NULL, '{ call set_account_gidnumber(?,?) }', '{ call del_account_gidnumber(?,?) }', 1, 0);
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
INSERT INTO ldap_attr_mappings VALUES (15, 4, 'memberUid', 'posix_account.uid', NULL, 'posix_account,groups_users,groups', 'groups_users.memberuid=posix_account.uidnumber AND groups_users.gidnumber=groups.gidnumber', NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (17, 3, 'gecos', 'posix_account.gecos', NULL, 'posix_account', NULL, '{ call set_account_gecos(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (73, 3, 'sambaNTPassword', 'samba_sam_account.sambantpassword', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambantpassword(?,?) }', '{ call del_account_sambantpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (74, 3, 'sambaPwdLastSet', 'samba_sam_account.sambapwdlastset', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdlastset(?,?) }', '{ call del_account_sambapwdlastset(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (4, 3, 'userPassword', 'posix_account.userpassword', NULL, 'posix_account', NULL, '{ call set_account_userpassword(?,?) }', '{ call del_account_userpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (112, 5, 'gidNumber', 'max(gidnumber)+1', NULL, 'groups', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (111, 5, 'uidNumber', 'max(uidnumber)+1
', NULL, 'posix_account', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (114, 6, 'sambaSID', 'sambadomain.sambasid', NULL, 'sambadomain', NULL, '{ call set_samba_domain_sid(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (113, 6, 'sambaDomainName', 'sambadomain.sambadomainname', NULL, 'sambadomain', NULL, '{ call set_samba_domain_name(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (75, 3, 'sambaLogonTime', 'samba_sam_account.sambalogontime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogontime(?,?) }', '{ call del_account_sambalogontime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (71, 3, 'sambaSID', 'samba_sam_account.sambasid', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambasid(?,?) }', '{ call del_account_sambasid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (76, 3, 'sambaLogoffTime', 'samba_sam_account.sambalogofftime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogofftime(?,?) }', '{ call del_account_sambalogofftime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (77, 3, 'sambaKickoffTime', 'samba_sam_account.sambakickofftime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambakickofftime(?,?) }', '{ call del_account_sambakickofftime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (79, 3, 'sambaPwdMustChange', 'samba_sam_account.sambapwdmustchange', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdmustchange(?,?) }', '{ call del_account_sambapwdmustchange(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (80, 3, 'sambaAcctFlags', 'samba_sam_account.sambaacctflags', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaacctflags(?,?) }', '{ call del_account_sambaacctflags(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (81, 3, 'displayName', 'samba_sam_account.displayname', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_displayname(?,?) }', '{ call del_account_displayname(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (82, 3, 'sambaHomePath', 'samba_sam_account.sambahomepath', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambahomepath(?,?) }', '{ call del_account_sambahomepath(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (83, 3, 'sambaHomeDrive', 'samba_sam_account.sambahomedrive', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambahomedrive(?,?) }', '{ call del_account_sambahomedrive(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (84, 3, 'sambaLogonScript', 'samba_sam_account.sambalogonscript', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogonscript(?,?) }', '{ call del_account_sambalogonscript(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (85, 3, 'sambaProfilePath', 'samba_sam_account.sambaprofilepath', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaprofilepath(?,?) }', '{ call del_account_sambaprofilepath(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (86, 3, 'description', 'samba_sam_account.description', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_description(?,?) }', '{ call del_account_description(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (88, 3, 'sambaPrimaryGroupSID', 'samba_sam_account.sambaprimarygroupsid', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaprimarygroupsid(?,?) }', '{ call del_account_sambaprimarygroupsid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (89, 3, 'sambaDomainName', 'samba_sam_account.sambadomainname', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambadomainname(?,?) }', '{ call del_account_sambadomainname(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (90, 3, 'sambaMungedDial', 'samba_sam_account.sambamungeddial', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambamungeddial(?,?) }', '{ call del_account_sambamungeddial(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (91, 3, 'sambaBadPasswordCount', 'samba_sam_account.sambabadpasswordcount', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambabadpasswordcount(?,?) }', '{ call del_account_sambabadpasswordcount(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (92, 3, 'sambaBadPasswordTime', 'samba_sam_account.sambabadpasswordtime', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambabadpasswordtime(?,?) }', '{ call del_account_sambabadpasswordtime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (93, 3, 'sambaPasswordHistory', 'samba_sam_account.sambapasswordhistory', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapasswordhistory(?,?) }', '{ call del_account_sambapasswordhistory(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (72, 3, 'sambaLMPassword', 'samba_sam_account.sambalmpassword', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalmpassword(?,?) }', '{ call del_account_sambalmpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (87, 3, 'sambaUserWorkstations', 'samba_sam_account.sambauserworkstations', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambauserworkstations(?,?) }', '{ call del_account_sambauserworkstations(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (78, 3, 'sambaPwdCanChange', 'samba_sam_account.sambapwdcanchange', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdcanchange(?,?) }', '{ call del_account_sambapwdcanchange(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (94, 3, 'sambaLogonHours', 'samba_sam_account.sambalogonhours', 'NULL', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogonhours(?,?) }', '{ call del_account_sambalogonhours(?,?) }', 1, 0);


--
-- Data for TOC entry 140 (OID 82403)
-- Name: ldap_entries; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_entries VALUES (1, 'dc=linuxmuster,dc=de', 1, 0, 1);
INSERT INTO ldap_entries VALUES (5, 'ou=groups,dc=linuxmuster,dc=de', 2, 1, 5);
INSERT INTO ldap_entries VALUES (2, 'ou=accounts,dc=linuxmuster,dc=de', 2, 1, 1);
INSERT INTO ldap_entries VALUES (3, 'ou=machines,dc=linuxmuster,dc=de', 2, 1, 3);
INSERT INTO ldap_entries VALUES (4, 'cn=NextFreeUnixId,dc=linuxmuster,dc=de', 3, 1, 10000);
INSERT INTO ldap_entries VALUES (3700, 'cn=Domain Admins,ou=groups,dc=linuxmuster,dc=de', 4, 5, 47);
INSERT INTO ldap_entries VALUES (3701, 'cn=machines,ou=groups,dc=linuxmuster,dc=de', 4, 5, 48);
INSERT INTO ldap_entries VALUES (3702, 'cn=linuxmuster,ou=groups,dc=linuxmuster,dc=de', 4, 5, 49);
INSERT INTO ldap_entries VALUES (3703, 'uid=administrator,ou=accounts,dc=linuxmuster,dc=de', 3, 2, 10001);
INSERT INTO ldap_entries VALUES (3704, 'sambaDomainName=MUSTERLOESUNG,dc=linuxmuster,dc=de', 6, 1, 10002);
INSERT INTO ldap_entries VALUES (3706, 'uid=root,ou=accounts,dc=linuxmuster,dc=de', 3, 2, 10002);
INSERT INTO ldap_entries VALUES (3707, 'uid=unstable$,ou=accounts,dc=linuxmuster,dc=de', 3, 2, 10003);
INSERT INTO ldap_entries VALUES (3708, 'uid=thomash,ou=accounts,dc=linuxmuster,dc=de', 3, 2, 10004);
INSERT INTO ldap_entries VALUES (3709, 'uid=testuser,ou=accounts,dc=linuxmuster,dc=de', 3, 2, 10005);


--
-- Data for TOC entry 141 (OID 82406)
-- Name: ldap_entry_objclasses; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_entry_objclasses VALUES (4, 'sambaUnixIdPool');
INSERT INTO ldap_entry_objclasses VALUES (3700, 'sambaGroupMapping');
INSERT INTO ldap_entry_objclasses VALUES (3701, 'sambaGroupMapping');
INSERT INTO ldap_entry_objclasses VALUES (3702, 'sambaGroupMapping');
INSERT INTO ldap_entry_objclasses VALUES (3703, 'top');
INSERT INTO ldap_entry_objclasses VALUES (3703, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (3703, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (3703, 'sambaSamAccount');
INSERT INTO ldap_entry_objclasses VALUES (3706, 'top');
INSERT INTO ldap_entry_objclasses VALUES (3706, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (3706, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (3706, 'sambaSamAccount');
INSERT INTO ldap_entry_objclasses VALUES (3707, 'top');
INSERT INTO ldap_entry_objclasses VALUES (3707, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (3707, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (3707, 'sambaSamAccount');
INSERT INTO ldap_entry_objclasses VALUES (3708, 'top');
INSERT INTO ldap_entry_objclasses VALUES (3708, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (3708, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (3708, 'sambaSamAccount');
INSERT INTO ldap_entry_objclasses VALUES (3709, 'top');
INSERT INTO ldap_entry_objclasses VALUES (3709, 'posixAccount');
INSERT INTO ldap_entry_objclasses VALUES (3709, 'shadowAccount');
INSERT INTO ldap_entry_objclasses VALUES (3709, 'sambaSamAccount');


--
-- Data for TOC entry 142 (OID 82410)
-- Name: institutes; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO institutes VALUES (1, 'linuxmuster');


--
-- Data for TOC entry 143 (OID 82413)
-- Name: ldap_referrals; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_referrals VALUES (1, 'Referral                                                                                                                                                                                                                                                       ', 'ldap://localhost/                                                                                                                                                                                                                                              ');


--
-- Data for TOC entry 144 (OID 82415)
-- Name: groups_users; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO groups_users VALUES (512, 500);


--
-- Data for TOC entry 145 (OID 82417)
-- Name: groups_groups; Type: TABLE DATA; Schema: public; Owner: ldap
--



--
-- Data for TOC entry 146 (OID 82424)
-- Name: samba_group_mapping; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO samba_group_mapping VALUES (47, 512, 'S-1-5-21-2472895434-561457303-1425298838-2025', '2', 'Domain Admins', NULL, NULL);
INSERT INTO samba_group_mapping VALUES (48, 10001, 'S-1-5-21-2472895434-561457303-1425298838-21003', '2', 'machines', NULL, NULL);
INSERT INTO samba_group_mapping VALUES (49, 10000, 'S-1-5-21-2472895434-561457303-1425298838-21001', '2', 'linuxmuster', NULL, NULL);


--
-- Data for TOC entry 147 (OID 82448)
-- Name: organizational_unit; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO organizational_unit VALUES (5, 'groups', 'Gruppen');
INSERT INTO organizational_unit VALUES (1, 'accounts', 'PosixAccounts');
INSERT INTO organizational_unit VALUES (3, 'machines', 'Maschinen');


--
-- Data for TOC entry 148 (OID 82483)
-- Name: groups; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO groups VALUES (47, 512, 'Domain Admins');
INSERT INTO groups VALUES (48, 10001, 'machines');
INSERT INTO groups VALUES (49, 10000, 'linuxmuster');


--
-- Data for TOC entry 149 (OID 82491)
-- Name: posix_account; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO posix_account VALUES (10000, 70000, 'NextFreeUnixId', 80000, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO posix_account VALUES (10001, 500, 'administrator', 512, 'Administrator', '', '/home/administrator', 'Administrator', '/bin/bash', '{SSHA}sKo2aYa6ZVk6FcpJvP9zIEB7r9JyRnFa', NULL);
INSERT INTO posix_account VALUES (10002, 501, 'root', 512, 'root', '', '/home/administrator', 'root', '/bin/bash', '{SSHA}R83CRdqjAEVPMjrlDcO06VdUyjdOZWF0', NULL);
INSERT INTO posix_account VALUES (10003, 1400, 'unstable$', 10001, 'unstable$', '', '/home/unstable$', 'System User', '/bin/bash', '{crypt}x', NULL);
INSERT INTO posix_account VALUES (10005, 11001, 'testuser', 10000, 'testuser', '', '/home/testuser', 'System User', '/bin/bash', '{SSHA}LFLtu4d+BpeOVnKsEw8ta0SldNFlRG50', NULL);
INSERT INTO posix_account VALUES (10004, 11000, 'thomash', 10000, 'Thomas', 'Hoth', '/home/ldap/thomash/', 'Thomas Hoth,,,,', '/bin/false', '{SSHA}dDVW+Z7BHdlDiF12Q35YjQY2RIgNmp2D', NULL);


--
-- Data for TOC entry 150 (OID 82497)
-- Name: samba_sam_account; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO samba_sam_account VALUES (10001, 'S-1-5-21-2472895434-561457303-1425298838-2000', NULL, 'DF1FB627AA2748B6AAD3B435B51404EE', '64E39492A161B94BF8EBDF8CADB72D32', '1122895350', '0', '2147483647', '2147483647', '0', '2147483647', '[UX]', 'Administrator', NULL, NULL, NULL, NULL, 'Administrator', NULL, 'S-1-5-21-2472895434-561457303-1425298838-2025', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO samba_sam_account VALUES (10002, 'S-1-5-21-2472895434-561457303-1425298838-2002', NULL, 'DF1FB627AA2748B6AAD3B435B51404EE', '64E39492A161B94BF8EBDF8CADB72D32', '1122896791', '0', '2147483647', '2147483647', '0', '2147483647', '[UX]', 'root', NULL, NULL, NULL, NULL, 'root', NULL, 'S-1-5-21-2472895434-561457303-1425298838-2025', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO samba_sam_account VALUES (10003, 'S-1-5-21-2472895434-561457303-1425298838-41002', NULL, NULL, 'CB4FDFB8830B93F5FB3E8B3C2717817D', '1122897058', NULL, NULL, NULL, '1122897058', '2147483647', '[W          ]', 'System User', NULL, NULL, NULL, NULL, 'System User', NULL, 'S-1-5-21-2472895434-561457303-1425298838-41001', NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO samba_sam_account VALUES (10004, 'S-1-5-21-2472895434-561457303-1425298838-23000', NULL, 'DF1FB627AA2748B6AAD3B435B51404EE', '64E39492A161B94BF8EBDF8CADB72D32', '1122905932', '0', '2147483647', '2147483647', '1122905932', '2147483647', '[UX]', 'Thomas Hoth', NULL, NULL, NULL, '\\\\preciosa\\profiles\\thomash', 'Thomas Hoth', NULL, 'S-1-5-21-2472895434-561457303-1425298838-21001', NULL, NULL, NULL, NULL, '0000000000000000000000000000000000000000000000000000000000000000', NULL);
INSERT INTO samba_sam_account VALUES (10005, 'S-1-5-21-2472895434-561457303-1425298838-23002', NULL, 'DF1FB627AA2748B6AAD3B435B51404EE', '64E39492A161B94BF8EBDF8CADB72D32', '1122906143', '0', '2147483647', '2147483647', '0', '2147483647', '[UX]', 'System User', NULL, NULL, NULL, NULL, 'System User', NULL, 'S-1-5-21-2472895434-561457303-1425298838-21001', NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Data for TOC entry 151 (OID 82504)
-- Name: ldap_oc_mappings; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_oc_mappings VALUES (1, 'organization', 'institutes', 'id', NULL, NULL, 0);
INSERT INTO ldap_oc_mappings VALUES (4, 'posixGroup', 'groups', 'id', 'SELECT create_groups()', NULL, 0);
INSERT INTO ldap_oc_mappings VALUES (2, 'organizationalUnit', 'organizational_unit', 'id', 'SELECT create_organizational_unit()', 'SELECT delete_organizational_unit(?)', 0);
INSERT INTO ldap_oc_mappings VALUES (6, 'sambaDomain', 'sambadomain', 'id', 'SELECT create_samba_domain()', NULL, 0);
INSERT INTO ldap_oc_mappings VALUES (3, 'inetOrgPerson', 'posix_account', 'id', 'SELECT create_account()', 'SELECT delete_account(?)', 0);


--
-- Data for TOC entry 152 (OID 82511)
-- Name: posix_account_details; Type: TABLE DATA; Schema: public; Owner: ldap
--



--
-- Data for TOC entry 153 (OID 82516)
-- Name: sambaunixidpool; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO sambaunixidpool VALUES (1, 'NextFreeUnixId');


--
-- Data for TOC entry 154 (OID 82523)
-- Name: sambadomain; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO sambadomain VALUES (10002, 'MUSTERLOESUNG', 'S-1-5-21-2472895434-561457303-1425298838');


--
-- TOC entry 35 (OID 82627)
-- Name: ldap_entries_ocmapid; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_ocmapid ON ldap_entries USING btree (oc_map_id);


--
-- TOC entry 37 (OID 82628)
-- Name: ldap_entry_objclasses_ocname; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entry_objclasses_ocname ON ldap_entry_objclasses USING btree (oc_name);


--
-- TOC entry 32 (OID 82629)
-- Name: ldap_entries_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_id ON ldap_entries USING btree (id);


--
-- TOC entry 34 (OID 82630)
-- Name: ldap_entries_keyval; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_keyval ON ldap_entries USING btree (keyval);


--
-- TOC entry 40 (OID 82631)
-- Name: samba_group_mapping_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX samba_group_mapping_id ON samba_group_mapping USING btree (id);


--
-- TOC entry 41 (OID 82632)
-- Name: samba_group_mapping_id_h; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX samba_group_mapping_id_h ON samba_group_mapping USING hash (id);


--
-- TOC entry 46 (OID 82633)
-- Name: groups_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX groups_id ON groups USING btree (id);


--
-- TOC entry 36 (OID 82634)
-- Name: ldap_entry_objclasses_entry_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entry_objclasses_entry_id ON ldap_entry_objclasses USING btree (entry_id);


--
-- TOC entry 50 (OID 82635)
-- Name: posix_account_id_uidnumber; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX posix_account_id_uidnumber ON posix_account USING btree (id, uidnumber);


--
-- TOC entry 30 (OID 82636)
-- Name: ldap_entries_dn; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_dn ON ldap_entries USING btree (dn);


--
-- TOC entry 42 (OID 82637)
-- Name: organizational_unit_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX organizational_unit_id ON organizational_unit USING btree (id);


--
-- TOC entry 38 (OID 82638)
-- Name: institutesid; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX institutesid ON institutes USING btree (id);


--
-- TOC entry 31 (OID 82639)
-- Name: ldap_entries_dnupper; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_dnupper ON ldap_entries USING btree (upper((dn)::text));


--
-- TOC entry 45 (OID 82640)
-- Name: groups_gidnumberup; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX groups_gidnumberup ON groups USING btree (upper((gidnumber)::text));


--
-- TOC entry 48 (OID 82641)
-- Name: pac_uidnumberup; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX pac_uidnumberup ON posix_account USING btree (upper((uidnumber)::text));


--
-- TOC entry 47 (OID 82642)
-- Name: groups_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_id_key UNIQUE (id);


--
-- TOC entry 44 (OID 82644)
-- Name: groups_gidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_gidnumber_key UNIQUE (gidnumber);


--
-- TOC entry 43 (OID 82646)
-- Name: groups_gid_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_gid_key UNIQUE (gid);


--
-- TOC entry 49 (OID 82648)
-- Name: posix_account_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_id_key UNIQUE (id);

ALTER TABLE posix_account CLUSTER ON posix_account_id_key;


--
-- TOC entry 52 (OID 82650)
-- Name: posix_account_uidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_uidnumber_key UNIQUE (uidnumber);


--
-- TOC entry 51 (OID 82652)
-- Name: posix_account_uid_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_uid_key UNIQUE (uid);


--
-- TOC entry 53 (OID 82654)
-- Name: samba_sam_account_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY samba_sam_account
    ADD CONSTRAINT samba_sam_account_id_key UNIQUE (id);


--
-- TOC entry 54 (OID 82656)
-- Name: ldap_oc_mappings_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY ldap_oc_mappings
    ADD CONSTRAINT ldap_oc_mappings_id_key UNIQUE (id);


--
-- TOC entry 33 (OID 82658)
-- Name: ldap_entries_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY ldap_entries
    ADD CONSTRAINT ldap_entries_id_key UNIQUE (id);


--
-- TOC entry 39 (OID 82660)
-- Name: samba_group_mapping_gidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY samba_group_mapping
    ADD CONSTRAINT samba_group_mapping_gidnumber_key UNIQUE (gidnumber, id);


--
-- TOC entry 55 (OID 82662)
-- Name: posix_account_details_uidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account_details
    ADD CONSTRAINT posix_account_details_uidnumber_key UNIQUE (id);


--
-- TOC entry 21 (OID 82396)
-- Name: ldap_attr_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_attr_mappings_id_seq', 114, true);


--
-- TOC entry 22 (OID 82401)
-- Name: ldap_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_entries_id_seq', 3710, true);


--
-- TOC entry 23 (OID 82408)
-- Name: institutes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('institutes_id_seq', 2, true);


--
-- TOC entry 24 (OID 82422)
-- Name: samba_group_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('samba_group_mapping_id_seq', 1, false);


--
-- TOC entry 25 (OID 82446)
-- Name: organizational_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('organizational_unit_id_seq', 6, true);


--
-- TOC entry 26 (OID 82481)
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('groups_id_seq', 49, true);


--
-- TOC entry 27 (OID 82489)
-- Name: posix_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('posix_account_id_seq', 10006, true);


--
-- TOC entry 28 (OID 82502)
-- Name: ldap_oc_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_oc_mappings_id_seq', 8, true);


--
-- TOC entry 29 (OID 82521)
-- Name: sambadomain_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('sambadomain_id_seq', 1, false);


SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 3 (OID 2200)
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


--
-- Create a view for userdata
--
CREATE OR REPLACE VIEW userdata AS SELECT posix_account.uidnumber, posix_account.uid, posix_account.gidnumber, posix_account.firstname, posix_account.surname, posix_account.homedirectory, posix_account.gecos, posix_account.loginshell, posix_account.userpassword, posix_account.description, samba_sam_account.sambasid, samba_sam_account.cn, samba_sam_account.sambalmpassword, samba_sam_account.sambantpassword, samba_sam_account.sambapwdlastset, samba_sam_account.sambalogontime, samba_sam_account.sambalogofftime, samba_sam_account.sambakickofftime, samba_sam_account.sambapwdcanchange, samba_sam_account.sambapwdmustchange, samba_sam_account.sambaacctflags, samba_sam_account.displayname, samba_sam_account.sambahomepath, samba_sam_account.sambahomedrive, samba_sam_account.sambalogonscript, samba_sam_account.sambaprofilepath, samba_sam_account.sambauserworkstations, samba_sam_account.sambaprimarygroupsid, samba_sam_account.sambadomainname, samba_sam_account.sambamungeddial, samba_sam_account.sambabadpasswordcount, samba_sam_account.sambabadpasswordtime, samba_sam_account.sambapasswordhistory, samba_sam_account.sambalogonhours, posix_account_details.schoolnumber, posix_account_details.unid, posix_account_details.birthname, posix_account_details.title, posix_account_details.gender, posix_account_details.birthday, posix_account_details.birthpostalcode, posix_account_details.birthcity, posix_account_details.denomination, posix_account_details.class, posix_account_details.classentry, posix_account_details.schooltype, posix_account_details.chiefinstructor, posix_account_details.nationality, posix_account_details.religionparticipation, posix_account_details.ethicsparticipation, posix_account_details.education, posix_account_details.occupation, posix_account_details.starttraining, posix_account_details.endtraining FROM posix_account FULL OUTER JOIN samba_sam_account ON posix_account.id=samba_sam_account.id FULL OUTER JOIN posix_account_details ON posix_account_details.id=posix_account.id;

