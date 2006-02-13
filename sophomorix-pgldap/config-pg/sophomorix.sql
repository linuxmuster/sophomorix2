--
-- PostgreSQL database dump
--

SET client_encoding = 'LATIN9';
SET check_function_bodies = false;

SET search_path = public, pg_catalog;

--
-- TOC entry 58 (OID 21420)
-- Name: plpgsql_call_handler(); Type: FUNC PROCEDURAL LANGUAGE; Schema: public; Owner: postgres
--

CREATE FUNCTION plpgsql_call_handler() RETURNS language_handler
    AS '$libdir/plpgsql', 'plpgsql_call_handler'
    LANGUAGE c;


--
-- TOC entry 57 (OID 21421)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: public; Owner: 
--

CREATE TRUSTED PROCEDURAL LANGUAGE plpgsql HANDLER plpgsql_call_handler;


--
-- TOC entry 5 (OID 64393)
-- Name: groups; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups (
    id serial NOT NULL,
    gidnumber integer NOT NULL,
    gid character varying NOT NULL
);


--
-- TOC entry 6 (OID 64399)
-- Name: groups_groups; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups_groups (
    gidnumber integer NOT NULL,
    membergid integer NOT NULL
);


--
-- TOC entry 7 (OID 64401)
-- Name: groups_users; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE groups_users (
    gidnumber integer NOT NULL,
    memberuidnumber integer NOT NULL
);

CREATE TABLE projects_memberprojects (
    projectid integer NOT NULL,
    memberprojectid integer NOT NULL
);

CREATE TABLE projects_admins (
    projectid integer NOT NULL,
    uidnumber integer NOT NULL
);


--
-- TOC entry 8 (OID 64405)
-- Name: institutes; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE institutes (
    id serial NOT NULL,
    name character varying(255)
);


--
-- TOC entry 9 (OID 64410)
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
-- TOC entry 10 (OID 64415)
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
-- TOC entry 11 (OID 64418)
-- Name: ldap_entry_objclasses; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_entry_objclasses (
    entry_id integer NOT NULL,
    oc_name character varying(64)
);


--
-- TOC entry 12 (OID 64422)
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
-- TOC entry 13 (OID 64425)
-- Name: ldap_referrals; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE ldap_referrals (
    entry_id integer,
    name character(255),
    url character(255)
);


--
-- TOC entry 14 (OID 64429)
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
-- TOC entry 15 (OID 64437)
-- Name: organizational_unit; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE organizational_unit (
    id serial NOT NULL,
    ou character varying(40) NOT NULL,
    description character varying(255)
);


--
-- TOC entry 16 (OID 64440)
-- Name: posix_account_details; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE posix_account_details (
    id integer NOT NULL,
    schoolnumber character varying(255),
    unid character varying(255),
    exitunid character varying(255),
    birthname character varying(255),
    title character varying(255),
    gender character varying(255),
    birthday date,
    birthpostalcode character varying(255),
    birthcity character varying(255),
    denomination character varying(255),
    "class" integer,
    adminclass character varying(255),
    exitadminclass character varying(255),
    subclass character varying(255),
    creationdate timestamp without time zone,
    tolerationdate date,
    deactivationdate date,
    sophomorixstatus character varying(255),
    accountstatus boolean,
    quota character varying(255),
    mailquota integer,
    firstpassword character varying(255),
    internetstatus boolean,
    emailstatus boolean,
    lastlogin date,
    lastgid integer,
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
-- TOC entry 17 (OID 64447)
-- Name: samba_domain; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE samba_domain (
    id serial NOT NULL,
    sambadomainname character varying,
    sambasid character varying
);


--
-- TOC entry 18 (OID 64455)
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
-- TOC entry 19 (OID 64461)
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



CREATE FUNCTION manual_delete_groups(character varying) RETURNS integer
AS '
DECLARE
groupname ALIAS FOR $1;
groups_id INTEGER;
get_gidnumber INTEGER;
ldap_entries_id INTEGER;
BEGIN
SELECT INTO groups_id id FROM groups WHERE gid=groupname;
SELECT INTO get_gidnumber gidnumber FROM groups WHERE gid=groupname;
SELECT INTO ldap_entries_id id FROM ldap_entries WHERE keyval=groups_id AND oc_map_id=4;

DELETE FROM ldap_entries WHERE id=ldap_entries_id;
DELETE FROM groups_users WHERE gidnumber=get_gidnumber;
DELETE FROM ldap_entry_objclasses WHERE entry_id=ldap_entries_id;
DELETE FROM groups WHERE id=groups_id;
DELETE FROM samba_group_mapping WHERE id=groups_id;

RETURN get_gidnumber;
END;
'
LANGUAGE plpgsql;



--
-- TOC entry 59 (OID 64466)
-- Name: create_account(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_account() RETURNS integer
    AS 'SELECT setval (''posix_account_id_seq'', (select case when max(id) is null then 1 else max(id) end from posix_account));
INSERT INTO posix_account (id,uidnumber,uid,gidnumber) VALUES (nextval(''posix_account_id_seq''),00,0,0);
INSERT INTO samba_sam_account (id) VALUES ((SELECT max(id) FROM posix_account));
SELECT max(id) FROM posix_account'
    LANGUAGE sql;


--
-- TOC entry 60 (OID 64467)
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
-- TOC entry 61 (OID 64468)
-- Name: manual_create_ldap_for_account(character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION manual_create_ldap_for_account(character varying) RETURNS integer
    AS ' 
    DECLARE
     username ALIAS FOR $1;
     posix_account_id INTEGER;
     ldap_entries_id INTEGER;
    BEGIN
     SELECT INTO posix_account_id nextval(''posix_account_id_seq'');
     SELECT INTO ldap_entries_id nextval(''ldap_entries_id_seq'');
     
     INSERT INTO ldap_entries (id,dn,oc_map_id,parent,keyval) VALUES (ldap_entries_id,''uid=''||username||'',ou=accounts,dc=linuxmuster,dc=de'',3,2,posix_account_id);
     
     INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES (ldap_entries_id,''top'');
     INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES (ldap_entries_id,''posixAccount'');
     INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES (ldap_entries_id,''shadowAccount'');
     INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES (ldap_entries_id,''sambaSamAccount'');
     
     RETURN posix_account_id;
    END;
    '
    LANGUAGE plpgsql;


--
-- TOC entry 62 (OID 64469)
-- Name: manual_delete_account(character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION manual_delete_account(character varying) RETURNS integer
    AS '
    DECLARE
     username ALIAS FOR $1;
     posix_account_id INTEGER;
     get_uidnumber INTEGER;
     ldap_entries_id INTEGER;
    BEGIN
     SELECT INTO posix_account_id id FROM posix_account WHERE uid=username;
     SELECT INTO get_uidnumber uidnumber FROM posix_account WHERE uid=username;
     SELECT INTO ldap_entries_id id FROM ldap_entries WHERE keyval=posix_account_id AND oc_map_id=3;

     DELETE FROM ldap_entries WHERE id=ldap_entries_id;
     DELETE FROM groups_users WHERE memberuidnumber=get_uidnumber;
     DELETE FROM ldap_entry_objclasses WHERE entry_id=ldap_entries_id;
     DELETE FROM posix_account WHERE id=posix_account_id;
     DELETE FROM posix_account_details WHERE id=posix_account_id;
     DELETE FROM samba_sam_account WHERE id=posix_account_id;

     RETURN get_uidnumber;
    END;
    '
    LANGUAGE plpgsql;


--
-- TOC entry 63 (OID 64470)
-- Name: manual_create_ldap_for_group(character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION manual_create_ldap_for_group(character varying) RETURNS integer
    AS '
    DECLARE
     groupname ALIAS FOR $1;
     groups_id INTEGER;
     ldap_entries_id INTEGER;
     BEGIN
     SELECT INTO groups_id nextval(''groups_id_seq'');
     SELECT INTO ldap_entries_id nextval(''ldap_entries_id_seq'');

     INSERT INTO ldap_entries (id,dn,oc_map_id,parent,keyval) VALUES (ldap_entries_id,''cn=''||groupname||'',ou=groups,dc=linuxmuster,dc=de'',4,5,groups_id);

     INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES (ldap_entries_id,''sambaGroupMapping'');

     RETURN groups_id;
    END;
    '
    LANGUAGE plpgsql;


--
-- TOC entry 64 (OID 64471)
-- Name: manual_get_next_free_gid(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION manual_get_next_free_gid() RETURNS integer
    AS '
    DECLARE
     get_gidnumber INTEGER;
     BEGIN
     SELECT INTO get_gidnumber gidnumber from posix_account WHERE uid=''NextFreeUnixId'';
     UPDATE posix_account set gidnumber=get_gidnumber+1 WHERE uid=''NextFreeUnixId'';

     RETURN get_gidnumber;
    END;
    '
    LANGUAGE plpgsql;


--
-- TOC entry 65 (OID 64472)
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
-- TOC entry 66 (OID 64473)
-- Name: create_samba_domain(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION create_samba_domain() RETURNS integer
    AS 'INSERT INTO samba_domain (id,sambadomainname,sambasid) VALUES (nextval(''posix_account_id_seq''),0,0);
SELECT max(id) FROM samba_domain'
    LANGUAGE sql;


--
-- TOC entry 67 (OID 64474)
-- Name: del_account_description(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_description(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET description=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 68 (OID 64475)
-- Name: del_account_displayname(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_displayname(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET displayname=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 69 (OID 64476)
-- Name: del_account_firstname(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_firstname(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET firstname=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 70 (OID 64477)
-- Name: del_account_gecos(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_gecos(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET gecos=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 71 (OID 64478)
-- Name: del_account_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_gidnumber(integer, integer) RETURNS integer
    AS '        UPDATE posix_account SET gidnumber=1 WHERE id=CAST($1 AS INT);
        SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 72 (OID 64479)
-- Name: del_account_homedirectory(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_homedirectory(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET homedirectory=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 73 (OID 64480)
-- Name: del_account_loginshell(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_loginshell(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET loginshell=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 74 (OID 64481)
-- Name: del_account_sambaacctflags(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambaacctflags(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaacctflags=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 75 (OID 64482)
-- Name: del_account_sambabadpasswordcount(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambabadpasswordcount(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordcount=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 76 (OID 64483)
-- Name: del_account_sambabadpasswordtime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambabadpasswordtime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordtime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 77 (OID 64484)
-- Name: del_account_sambadomainname(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambadomainname(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambadomainname=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 78 (OID 64485)
-- Name: del_account_sambahomedrive(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambahomedrive(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomedrive=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 79 (OID 64486)
-- Name: del_account_sambahomepath(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambahomepath(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomepath=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 80 (OID 64487)
-- Name: del_account_sambakickofftime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambakickofftime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambakickofftime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 81 (OID 64488)
-- Name: del_account_sambalmpassword(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalmpassword(integer, character varying) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambalmpassword=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 82 (OID 64489)
-- Name: del_account_sambalogofftime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogofftime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogofftime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 83 (OID 64490)
-- Name: del_account_sambalogonhours(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogonhours(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonhours=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 84 (OID 64491)
-- Name: del_account_sambalogonscript(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogonscript(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonscript=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 85 (OID 64492)
-- Name: del_account_sambalogontime(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambalogontime(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogontime=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 86 (OID 64493)
-- Name: del_account_sambamungeddial(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambamungeddial(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambamungeddial=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 87 (OID 64494)
-- Name: del_account_sambantpassword(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambantpassword(integer, character varying) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambantpassword=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 88 (OID 64495)
-- Name: del_account_sambapasswordhistory(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapasswordhistory(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapasswordhistory=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 89 (OID 64496)
-- Name: del_account_sambaprimarygroupsid(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambaprimarygroupsid(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprimarygroupsid=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 90 (OID 64497)
-- Name: del_account_sambaprofilepath(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambaprofilepath(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprofilepath=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 91 (OID 64498)
-- Name: del_account_sambapwdcanchange(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapwdcanchange(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdcanchange=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 92 (OID 64499)
-- Name: del_account_sambapwdlastset(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapwdlastset(integer, character varying) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambapwdlastset=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 93 (OID 64500)
-- Name: del_account_sambapwdmustchange(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambapwdmustchange(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdmustchange=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 94 (OID 64501)
-- Name: del_account_sambasid(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambasid(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambasid=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 95 (OID 64502)
-- Name: del_account_sambauserworkstations(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sambauserworkstations(integer, character varying) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambauserworkstations=NULL WHERE id=CAST($1 AS INT); SELECT $1 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 96 (OID 64503)
-- Name: del_account_sn(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_sn(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET surname=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 97 (OID 64504)
-- Name: del_account_uid(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_uid(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET uid=1 WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 98 (OID 64505)
-- Name: del_account_uidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_uidnumber(integer, integer) RETURNS integer
    AS 'UPDATE posix_account SET uidnumber=0 WHERE id=CAST($1 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 99 (OID 64506)
-- Name: del_account_userpassword(integer, character varying); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION del_account_userpassword(integer, character varying) RETURNS integer
    AS 'UPDATE posix_account SET userpassword=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN'
    LANGUAGE sql;


--
-- TOC entry 100 (OID 64507)
-- Name: delete_account(integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION delete_account(integer) RETURNS integer
    AS 'delete from posix_account where id=$1;
delete from samba_sam_account where id=$1;
SELECT max(id) FROM posix_account'
    LANGUAGE sql;


--
-- TOC entry 101 (OID 64508)
-- Name: delete_organizational_unit(integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION delete_organizational_unit(integer) RETURNS integer
    AS '
	DELETE FROM organizational_unit WHERE id=CAST($1 AS INT);
	SELECT $1 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 102 (OID 64509)
-- Name: manual_get_next_free_uid(); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION manual_get_next_free_uid() RETURNS integer
    AS ' 
    DECLARE
     get_uidnumber INTEGER;
    BEGIN
     SELECT INTO get_uidnumber uidnumber from posix_account WHERE uid=''NextFreeUnixId'';
     UPDATE posix_account set uidnumber=get_uidnumber+1 WHERE uid=''NextFreeUnixId'';

     RETURN get_uidnumber;
    END; 
    '
    LANGUAGE plpgsql;


--
-- TOC entry 103 (OID 64510)
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
-- TOC entry 104 (OID 64511)
-- Name: set_account_description(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_description(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET description=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 105 (OID 64512)
-- Name: set_account_displayname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_displayname(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET displayname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 106 (OID 64513)
-- Name: set_account_firstname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_firstname(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET firstname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 107 (OID 64514)
-- Name: set_account_gecos(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_gecos(character varying, integer) RETURNS integer
    AS 'UPDATE posix_account SET gecos=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 108 (OID 64515)
-- Name: set_account_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_gidnumber(integer, integer) RETURNS integer
    AS '
        UPDATE posix_account SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 109 (OID 64516)
-- Name: set_account_homedirectory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_homedirectory(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET homedirectory=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 110 (OID 64517)
-- Name: set_account_loginshell(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_loginshell(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET loginshell=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 111 (OID 64518)
-- Name: set_account_sambaacctflags(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaacctflags(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaacctflags=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 112 (OID 64519)
-- Name: set_account_sambabadpasswordcount(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambabadpasswordcount(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordcount=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 113 (OID 64520)
-- Name: set_account_sambabadpasswordtime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambabadpasswordtime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambabadpasswordtime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 114 (OID 64521)
-- Name: set_account_sambadomainname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambadomainname(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambadomainname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 115 (OID 64522)
-- Name: set_account_sambahomedrive(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambahomedrive(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomedrive=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 116 (OID 64523)
-- Name: set_account_sambahomepath(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambahomepath(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambahomepath=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 117 (OID 64524)
-- Name: set_account_sambakickofftime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambakickofftime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambakickofftime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 118 (OID 64525)
-- Name: set_account_sambalmpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalmpassword(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalmpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 119 (OID 64526)
-- Name: set_account_sambalogofftime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogofftime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogofftime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 120 (OID 64527)
-- Name: set_account_sambalogonhours(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogonhours(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonhours=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 121 (OID 64528)
-- Name: set_account_sambalogonscript(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogonscript(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogonscript=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 122 (OID 64529)
-- Name: set_account_sambalogontime(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambalogontime(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambalogontime=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 123 (OID 64530)
-- Name: set_account_sambamungeddial(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambamungeddial(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambamungeddial=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 124 (OID 64531)
-- Name: set_account_sambantpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambantpassword(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambantpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 125 (OID 64532)
-- Name: set_account_sambapasswordhistory(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapasswordhistory(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapasswordhistory=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 126 (OID 64533)
-- Name: set_account_sambaprimarygroupsid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaprimarygroupsid(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprimarygroupsid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 127 (OID 64534)
-- Name: set_account_sambaprofilepath(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambaprofilepath(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambaprofilepath=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 128 (OID 64535)
-- Name: set_account_sambapwdcanchange(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdcanchange(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdcanchange=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 129 (OID 64536)
-- Name: set_account_sambapwdlastset(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdlastset(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdlastset=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 130 (OID 64537)
-- Name: set_account_sambapwdmustchange(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambapwdmustchange(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambapwdmustchange=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 131 (OID 64538)
-- Name: set_account_sambasid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambasid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_sam_account SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); 
INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES ((SELECT id from ldap_entries WHERE oc_map_id=3 AND keyval=$2),''sambaSamAccount'');
SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 132 (OID 64539)
-- Name: set_account_sambauserworkstations(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sambauserworkstations(character varying, integer) RETURNS integer
    AS ' UPDATE samba_sam_account SET sambauserworkstations=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;


--
-- TOC entry 133 (OID 64540)
-- Name: set_account_sn(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_sn(character varying, integer) RETURNS integer
    AS '        UPDATE posix_account SET surname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 134 (OID 64541)
-- Name: set_account_uid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_uid(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET uid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 135 (OID 64542)
-- Name: set_account_uidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_uidnumber(integer, integer) RETURNS integer
    AS 'UPDATE posix_account SET uidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 136 (OID 64543)
-- Name: set_account_userpassword(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_account_userpassword(character varying, integer) RETURNS integer
    AS '
        UPDATE posix_account SET userpassword=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 137 (OID 64544)
-- Name: set_groups_cn(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_cn(character varying, integer) RETURNS integer
    AS 'UPDATE groups SET gid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 138 (OID 64545)
-- Name: set_groups_description(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_description(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET description=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 139 (OID 64546)
-- Name: set_groups_displayname(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_displayname(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET displayname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 140 (OID 64547)
-- Name: set_groups_gidnumber(integer, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_gidnumber(integer, integer) RETURNS integer
    AS 'UPDATE groups SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
UPDATE samba_group_mapping SET gidnumber=CAST($1 AS INT) WHERE id=CAST($2 AS INT);
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 141 (OID 64548)
-- Name: set_groups_sambagrouptype(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambagrouptype(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET sambagrouptype=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 142 (OID 64549)
-- Name: set_groups_sambasid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambasid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_group_mapping SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
INSERT INTO ldap_entry_objclasses (entry_id,oc_name) VALUES ((SELECT id from ldap_entries WHERE oc_map_id=4 AND keyval=$2),''sambaGroupMapping'');
SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 143 (OID 64550)
-- Name: set_groups_sambasidlist(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_groups_sambasidlist(character varying, integer) RETURNS integer
    AS '        UPDATE samba_group_mapping SET sambasidlist=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
                SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 144 (OID 64551)
-- Name: set_organizational_unit_ou(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_organizational_unit_ou(character varying, integer) RETURNS integer
    AS '
	UPDATE organizational_unit SET ou=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT);
        SELECT $2 AS RETURN
'
    LANGUAGE sql;


--
-- TOC entry 145 (OID 64552)
-- Name: set_samba_domain_name(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_samba_domain_name(character varying, integer) RETURNS integer
    AS 'UPDATE samba_domain SET sambadomainname=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;



CREATE FUNCTION delete_groups(integer) RETURNS integer
AS 'delete from groups where id=$1;
delete from samba_group_mapping where id=$1;
SELECT max(id) FROM groups'
LANGUAGE sql;


CREATE FUNCTION del_groups_displayname(integer, character varying) RETURNS integer
AS '
UPDATE samba_group_mapping SET displayname=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

CREATE FUNCTION del_groups_sambasid(integer, character varying) RETURNS integer
AS '
UPDATE samba_group_mapping SET sambasid=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

CREATE FUNCTION del_groups_sambasidlist(integer, character varying) RETURNS integer
AS '
UPDATE samba_group_mapping SET sambasidlist=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

CREATE FUNCTION del_groups_description(integer, character varying) RETURNS integer
AS '
UPDATE samba_group_mapping SET description=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

CREATE FUNCTION del_groups_sambagrouptype(integer, character varying) RETURNS integer
AS '
UPDATE samba_group_mapping SET sambagrouptype=NULL WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

CREATE FUNCTION del_groups_gidnumber(integer, character varying) RETURNS integer
AS '
UPDATE groups SET gidnumber=0 WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

CREATE FUNCTION del_groups_cn(integer, character varying) RETURNS integer
AS '
UPDATE groups SET gid=''delete'' WHERE id=CAST($1 AS INT);
SELECT $1 AS RETURN
'
LANGUAGE sql;

--
-- TOC entry 146 (OID 64553)
-- Name: set_samba_domain_sid(character varying, integer); Type: FUNCTION; Schema: public; Owner: ldap
--

CREATE FUNCTION set_samba_domain_sid(character varying, integer) RETURNS integer
    AS 'UPDATE samba_domain SET sambasid=CAST($1 AS VARCHAR) WHERE id=CAST($2 AS INT); SELECT $2 AS RETURN '
    LANGUAGE sql;



CREATE VIEW memberdata AS SELECT posix_account.uid, posix_account.uidnumber as uidnum, posix_account.gecos,posix_account.gidnumber as adminclass, samba_sam_account.displayname,posix_account_details.sophomorixstatus as s,groups.gid FROM posix_account FULL JOIN samba_sam_account on posix_account.id = samba_sam_account.id FULL JOIN posix_account_details on posix_account.id=posix_account_details.sophomorixstatus INNER JOIN groups_users on groups_users.memberuidnumber=posix_account.uidnumber INNER JOIN groups on groups.gidnumber=groups_users.gidnumber;


--
-- TOC entry 20 (OID 64556)
-- Name: userdata; Type: VIEW; Schema: public; Owner: ldap
--

CREATE VIEW userdata AS
    SELECT posix_account.id, posix_account.uidnumber, posix_account.uid, posix_account.gidnumber, posix_account.firstname, posix_account.surname, posix_account.homedirectory, posix_account.gecos, posix_account.loginshell, posix_account.userpassword, posix_account.description, samba_sam_account.sambasid, samba_sam_account.cn, samba_sam_account.sambalmpassword, samba_sam_account.sambantpassword, samba_sam_account.sambapwdlastset, samba_sam_account.sambalogontime, samba_sam_account.sambalogofftime, samba_sam_account.sambakickofftime, samba_sam_account.sambapwdcanchange, samba_sam_account.sambapwdmustchange, samba_sam_account.sambaacctflags, samba_sam_account.displayname, samba_sam_account.sambahomepath, samba_sam_account.sambahomedrive, samba_sam_account.sambalogonscript, samba_sam_account.sambaprofilepath, samba_sam_account.sambauserworkstations, samba_sam_account.sambaprimarygroupsid, samba_sam_account.sambadomainname, samba_sam_account.sambamungeddial, samba_sam_account.sambabadpasswordcount, samba_sam_account.sambabadpasswordtime, samba_sam_account.sambapasswordhistory, samba_sam_account.sambalogonhours, posix_account_details.schoolnumber, posix_account_details.unid, posix_account_details.exitunid, posix_account_details.birthname, posix_account_details.title, posix_account_details.gender, posix_account_details.birthday, posix_account_details.birthpostalcode, posix_account_details.birthcity, posix_account_details.denomination, posix_account_details."class", posix_account_details.adminclass, posix_account_details.exitadminclass, posix_account_details.subclass, posix_account_details.creationdate, posix_account_details.tolerationdate, posix_account_details.deactivationdate, posix_account_details.sophomorixstatus, posix_account_details.accountstatus, posix_account_details.quota, posix_account_details.firstpassword, posix_account_details.internetstatus, posix_account_details.emailstatus, posix_account_details.lastlogin, posix_account_details.lastgid, posix_account_details.classentry, posix_account_details.schooltype, posix_account_details.chiefinstructor, posix_account_details.nationality, posix_account_details.religionparticipation, posix_account_details.ethicsparticipation, posix_account_details.education, posix_account_details.occupation, posix_account_details.starttraining, posix_account_details.endtraining, groups.gid FROM (((posix_account FULL JOIN samba_sam_account ON ((posix_account.id = samba_sam_account.id))) FULL JOIN posix_account_details ON ((posix_account_details.id = posix_account.id))) FULL JOIN groups ON ((posix_account.gidnumber = groups.gidnumber))) WHERE ((posix_account.uid)::text <> 'NextFreeUnixId'::text);


--
-- TOC entry 21 (OID 64558)
-- Name: class_details; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE class_details (
    id integer NOT NULL,
    quota character varying(255),
    schooltype character varying(255),
    department character varying(255),
    mailalias boolean,
    "type" character varying(255)
);


--
-- TOC entry 22 (OID 64560)
-- Name: project_details; Type: TABLE; Schema: public; Owner: ldap
--

CREATE TABLE project_details (
    id integer NOT NULL,
    addquota character varying(255),
    addmailquota integer,
    schooltype character varying(255),
    department character varying(255),
    sophomorixstatus character varying(255),
    enddate date,
    longname character varying(255),
    maxmebers integer,
    "type" integer,
    maxmembers integer,
    creationdate timestamp without time zone,
    tolerationdate date,
    deactivationdate date
);


--
-- TOC entry 24 (OID 64660)
-- Name: projectdata; Type: VIEW; Schema: public; Owner: ldap
--

CREATE VIEW projectdata AS
    SELECT project_details.id, project_details.addquota, project_details.addmailquota, project_details.schooltype, project_details.department, project_details.sophomorixstatus, project_details.enddate, project_details.longname, project_details.maxmebers, project_details."type", maxmembers, project_details.creationdate, project_details.tolerationdate, project_details.deactivationdate, groups.gid, groups.gidnumber, samba_group_mapping.sambasid, samba_group_mapping.sambagrouptype, samba_group_mapping.displayname, samba_group_mapping.description, samba_group_mapping.sambasidlist FROM ((project_details FULL JOIN groups ON ((project_details.id = groups.id))) FULL JOIN samba_group_mapping ON ((samba_group_mapping.id = groups.id)));


--
-- TOC entry 25 (OID 64663)
-- Name: classdata; Type: VIEW; Schema: public; Owner: ldap
--

CREATE VIEW classdata AS
    SELECT class_details.id, class_details.quota, class_details.schooltype, class_details.department, class_details."type", class_details.mailalias, groups.gid, groups.gidnumber, samba_group_mapping.sambasid, samba_group_mapping.sambagrouptype, samba_group_mapping.displayname, samba_group_mapping.description, samba_group_mapping.sambasidlist FROM ((class_details FULL JOIN groups ON ((class_details.id = groups.id))) FULL JOIN samba_group_mapping ON ((samba_group_mapping.id = groups.id)));


INSERT INTO institutes VALUES (1, 'linuxmuster');


--
-- Data for TOC entry 151 (OID 64410)
-- Name: ldap_attr_mappings; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_attr_mappings VALUES (97, 4, 'displayName', 'samba_group_mapping.displayname', 'samba_group_mapping.displayname', 'samba_group_mapping,groups', 'samba_group_mapping.id=groups.id', '{ call set_groups_displayname(?,?) }', '{ call del_groups_displayname(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (81, 3, 'displayName', 'samba_sam_account.displayname', 'samba_sam_account.displayname', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_displayname(?,?) }', '{ call del_account_displayname(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (71, 3, 'sambaSID', 'samba_sam_account.sambasid', 'samba_sam_account.sambasid', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambasid(?,?) }', '{ call del_account_sambasid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (114, 6, 'sambaSID', 'samba_domain.sambasid', 'samba_domain.sambasid', 'samba_domain', NULL, '{ call set_samba_domain_sid(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (95, 4, 'sambaSID', 'samba_group_mapping.sambasid', 'samba_group_mapping.sambasid', 'samba_group_mapping,groups', 'samba_group_mapping.id=groups.id', '{ call set_groups_sambasid(?,?) }', '{ call del_groups_sambasid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (99, 4, 'sambaSIDList', 'samba_group_mapping.sambasidlist', 'samba_group_mapping.sambasidlist', 'samba_group_mapping,groups', 'samba_group_mapping.id=groups.id', '{ call set_groups_sambasidlist(?,?) }', '{ call del_groups_sambasidlist(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (98, 4, 'description', 'samba_group_mapping.description', 'samba_group_mapping.description', 'samba_group_mapping,groups', 'samba_group_mapping.id=groups.id', '{ call set_groups_description(?,?) }', '{ call del_groups_description(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (96, 4, 'sambaGroupType', 'samba_group_mapping.sambagrouptype', 'samba_group_mapping.sambagrouptype', 'samba_group_mapping,groups', 'samba_group_mapping.id=groups.id', '{ call set_groups_sambagrouptype(?,?) }', '{ call del_groups_sambagrouptype(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (94, 3, 'sambaLogonHours', 'samba_sam_account.sambalogonhours', 'samba_sam_account.sambalogonhours', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogonhours(?,?) }', '{ call del_account_sambalogonhours(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (78, 3, 'sambaPwdCanChange', 'samba_sam_account.sambapwdcanchange', 'samba_sam_account.sambalogonhours', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdcanchange(?,?) }', '{ call del_account_sambapwdcanchange(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (87, 3, 'sambaUserWorkstations', 'samba_sam_account.sambauserworkstations', 'samba_sam_account.sambauserworkstations', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambauserworkstations(?,?) }', '{ call del_account_sambauserworkstations(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (72, 3, 'sambaLMPassword', 'samba_sam_account.sambalmpassword', 'samba_sam_account.sambalmpassword', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalmpassword(?,?) }', '{ call del_account_sambalmpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (93, 3, 'sambaPasswordHistory', 'samba_sam_account.sambapasswordhistory', 'samba_sam_account.sambalmpassword', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapasswordhistory(?,?) }', '{ call del_account_sambapasswordhistory(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (92, 3, 'sambaBadPasswordTime', 'samba_sam_account.sambabadpasswordtime', 'samba_sam_account.sambalmpassword', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambabadpasswordtime(?,?) }', '{ call del_account_sambabadpasswordtime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (91, 3, 'sambaBadPasswordCount', 'samba_sam_account.sambabadpasswordcount', 'samba_sam_account.sambabadpasswordcount', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambabadpasswordcount(?,?) }', '{ call del_account_sambabadpasswordcount(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (90, 3, 'sambaMungedDial', 'samba_sam_account.sambamungeddial', 'samba_sam_account.sambamungeddial', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambamungeddial(?,?) }', '{ call del_account_sambamungeddial(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (89, 3, 'sambaDomainName', 'samba_sam_account.sambadomainname', 'samba_sam_account.sambadomainname', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambadomainname(?,?) }', '{ call del_account_sambadomainname(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (88, 3, 'sambaPrimaryGroupSID', 'samba_sam_account.sambaprimarygroupsid', 'samba_sam_account.sambaprimarygroupsid', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaprimarygroupsid(?,?) }', '{ call del_account_sambaprimarygroupsid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (85, 3, 'sambaProfilePath', 'samba_sam_account.sambaprofilepath', 'samba_sam_account.sambaprofilepath', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaprofilepath(?,?) }', '{ call del_account_sambaprofilepath(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (84, 3, 'sambaLogonScript', 'samba_sam_account.sambalogonscript', 'samba_sam_account.sambalogonscript', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogonscript(?,?) }', '{ call del_account_sambalogonscript(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (83, 3, 'sambaHomeDrive', 'samba_sam_account.sambahomedrive', 'samba_sam_account.sambahomedrive', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambahomedrive(?,?) }', '{ call del_account_sambahomedrive(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (82, 3, 'sambaHomePath', 'samba_sam_account.sambahomepath', 'samba_sam_account.sambahomepath', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambahomepath(?,?) }', '{ call del_account_sambahomepath(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (80, 3, 'sambaAcctFlags', 'samba_sam_account.sambaacctflags', 'samba_sam_account.sambaacctflags', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambaacctflags(?,?) }', '{ call del_account_sambaacctflags(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (79, 3, 'sambaPwdMustChange', 'samba_sam_account.sambapwdmustchange', 'samba_sam_account.sambapwdmustchange', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdmustchange(?,?) }', '{ call del_account_sambapwdmustchange(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (77, 3, 'sambaKickoffTime', 'samba_sam_account.sambakickofftime', 'samba_sam_account.sambakickofftime', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambakickofftime(?,?) }', '{ call del_account_sambakickofftime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (76, 3, 'sambaLogoffTime', 'samba_sam_account.sambalogofftime', 'samba_sam_account.sambalogofftime', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogofftime(?,?) }', '{ call del_account_sambalogofftime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (75, 3, 'sambaLogonTime', 'samba_sam_account.sambalogontime', 'samba_sam_account.sambalogontime', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambalogontime(?,?) }', '{ call del_account_sambalogontime(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (74, 3, 'sambaPwdLastSet', 'samba_sam_account.sambapwdlastset', 'samba_sam_account.sambapwdlastset', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambapwdlastset(?,?) }', '{ call del_account_sambapwdlastset(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (73, 3, 'sambaNTPassword', 'samba_sam_account.sambantpassword', 'samba_sam_account.sambantpassword', 'samba_sam_account,posix_account', 'samba_sam_account.id=posix_account.id', '{ call set_account_sambantpassword(?,?) }', '{ call del_account_sambantpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (113, 6, 'sambaDomainName', 'samba_domain.sambadomainname', 'samba_domain.sambadomainname', 'samba_domain', NULL, '{ call set_samba_domain_name(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (105, 3, 'sn', 'posix_account.surname', NULL, 'posix_account', NULL, '{ call set_account_sn(?,?) }', '{ call del_account_sn(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (9, 3, 'uid', 'posix_account.uid', NULL, 'posix_account', NULL, '{ call set_account_uid(?,?) }', '{ call del_account_uid(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (12, 3, 'uidNumber', 'posix_account.uidnumber', NULL, 'posix_account', NULL, '{ call set_account_uidnumber(?,?) }', '{ call del_account_uidnumber(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (86, 3, 'description', 'posix_account.description', NULL, 'posix_account', NULL, '{ call set_account_description(?,?) }', '{ call del_account_description(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (106, 3, 'gn', 'posix_account.firstname', NULL, 'posix_account', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (5, 1, 'o', 'institutes.name', NULL, 'institutes', NULL, NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (17, 3, 'gecos', 'posix_account.gecos', NULL, 'posix_account', NULL, '{ call set_account_gecos(?,?) }', '{ call del_account_gecos(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (4, 3, 'userPassword', 'posix_account.userpassword', NULL, 'posix_account', NULL, '{ call set_account_userpassword(?,?) }', '{ call del_account_userpassword(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (15, 4, 'memberUid', 'posix_account.uid', NULL, 'posix_account,groups_users,groups', 'groups_users.memberuidnumber=posix_account.uidnumber AND groups_users.gidnumber=groups.gidnumber', NULL, NULL, 0, 0);
INSERT INTO ldap_attr_mappings VALUES (8, 2, 'ou', 'organizational_unit.ou', NULL, 'organizational_unit', NULL, '{ call set_organizational_unit_ou(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (10, 3, 'gidNumber', 'posix_account.gidnumber', NULL, 'posix_account', NULL, '{ call set_account_gidnumber(?,?) }', '{ call del_account_gidnumber(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (16, 3, 'loginShell', 'posix_account.loginshell', NULL, 'posix_account', NULL, '{ call set_account_loginshell(?,?) }', '{ call del_account_loginshell(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (11, 3, 'homeDirectory', 'posix_account.homedirectory', NULL, 'posix_account', NULL, '{ call set_account_homedirectory(?,?) }', '{ call del_account_homedirectory(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (1, 3, 'cn', 'posix_account.firstname || '' '' || posix_account.surname', NULL, 'posix_account', NULL, '{ call set_account_cn(?,?) }', NULL, 1, 0);
INSERT INTO ldap_attr_mappings VALUES (13, 4, 'gidNumber', 'groups.gidnumber', NULL, 'groups', NULL, '{ call set_groups_gidnumber(?,?) }', '{ call del_groups_gidnumber(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (14, 4, 'cn', 'groups.gid', NULL, 'groups', NULL, '{ call set_groups_cn(?,?) }', '{ call del_groups_cn(?,?) }', 1, 0);
INSERT INTO ldap_attr_mappings VALUES (7, 1, 'dc', 'institutes.name', NULL, 'institutes,ldap_entries AS dcObject,ldap_entry_objclasses as auxObjectClass', 'institutes.id=dcObject.keyval AND dcObject.oc_map_id=1 AND dcObject.id=auxObjectClass.entry_id AND auxObjectClass.oc_name=''dcObject''', NULL, NULL, 0, 0);


--
-- Data for TOC entry 152 (OID 64415)
-- Name: ldap_entries; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_entries VALUES (1, 'dc=linuxmuster,dc=de', 1, 0, 1);
INSERT INTO ldap_entries VALUES (5, 'ou=groups,dc=linuxmuster,dc=de', 2, 1, 5);
INSERT INTO ldap_entries VALUES (2, 'ou=accounts,dc=linuxmuster,dc=de', 2, 1, 1);
INSERT INTO ldap_entries VALUES (3, 'ou=machines,dc=linuxmuster,dc=de', 2, 1, 3);
INSERT INTO ldap_entries VALUES (4, 'cn=NextFreeUnixId,dc=linuxmuster,dc=de', 3, 1, 1);

--
-- Data for TOC entry 153 (OID 64418)
-- Name: ldap_entry_objclasses; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_entry_objclasses VALUES (4, 'sambaUnixIdPool');

--
-- Data for TOC entry 154 (OID 64422)
-- Name: ldap_oc_mappings; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_oc_mappings VALUES (1, 'organization', 'institutes', 'id', NULL, NULL, 0);
INSERT INTO ldap_oc_mappings VALUES (4, 'posixGroup', 'groups', 'id', 'SELECT create_groups()', 'SELECT delete_groups(?)', 0);
INSERT INTO ldap_oc_mappings VALUES (2, 'organizationalUnit', 'organizational_unit', 'id', 'SELECT create_organizational_unit()', 'SELECT delete_organizational_unit(?)', 0);
INSERT INTO ldap_oc_mappings VALUES (3, 'inetOrgPerson', 'posix_account', 'id', 'SELECT create_account()', 'SELECT delete_account(?)', 0);
INSERT INTO ldap_oc_mappings VALUES (6, 'sambaDomain', 'samba_domain', 'id', 'SELECT create_samba_domain()', NULL, 0);


--
-- Data for TOC entry 155 (OID 64425)
-- Name: ldap_referrals; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO ldap_referrals VALUES (1, 'Referral                                                                                                                                                                                                                                                       ', 'ldap://localhost/                                                                                                                                                                                                                                              ');


--
-- Data for TOC entry 156 (OID 64429)
-- Name: posix_account; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO posix_account VALUES (1, 10013, 'NextFreeUnixId', 10000, '', 'NextFreeUnixId', '', '', '', '', '                                                                                                                                                                                                                                                               ');
--
-- Data for TOC entry 157 (OID 64437)
-- Name: organizational_unit; Type: TABLE DATA; Schema: public; Owner: ldap
--

INSERT INTO organizational_unit VALUES (5, 'groups', 'Gruppen');
INSERT INTO organizational_unit VALUES (1, 'accounts', 'PosixAccounts');
INSERT INTO organizational_unit VALUES (3, 'machines', 'Maschinen');


--
-- TOC entry 37 (OID 64627)
-- Name: groups_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX groups_id ON groups USING btree (id);


--
-- TOC entry 39 (OID 64628)
-- Name: institutesid; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX institutesid ON institutes USING btree (id);


--
-- TOC entry 44 (OID 64629)
-- Name: ldap_entry_objclasses_entry_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entry_objclasses_entry_id ON ldap_entry_objclasses USING btree (entry_id);


--
-- TOC entry 45 (OID 64630)
-- Name: ldap_entry_objclasses_ocname; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entry_objclasses_ocname ON ldap_entry_objclasses USING btree (oc_name);


--
-- TOC entry 51 (OID 64631)
-- Name: organizational_unit_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX organizational_unit_id ON organizational_unit USING btree (id);


--
-- TOC entry 47 (OID 64632)
-- Name: pac_uidnumberup; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX pac_uidnumberup ON posix_account USING btree (upper((uidnumber)::text));

ALTER TABLE posix_account CLUSTER ON pac_uidnumberup;


--
-- TOC entry 54 (OID 64633)
-- Name: samba_group_mapping_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX samba_group_mapping_id ON samba_group_mapping USING btree (id);


--
-- TOC entry 55 (OID 64634)
-- Name: samba_group_mapping_id_h; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX samba_group_mapping_id_h ON samba_group_mapping USING hash (id);


--
-- TOC entry 40 (OID 64635)
-- Name: ldap_entries_dn; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX ldap_entries_dn ON ldap_entries USING btree (dn);


--
-- TOC entry 41 (OID 64636)
-- Name: ldap_entries_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX ldap_entries_id ON ldap_entries USING btree (id);


--
-- TOC entry 43 (OID 64637)
-- Name: ldap_entries_keyval; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX ldap_entries_keyval ON ldap_entries USING btree (keyval);


--
-- TOC entry 49 (OID 64638)
-- Name: posix_account_id; Type: INDEX; Schema: public; Owner: ldap
--

CREATE UNIQUE INDEX posix_account_id ON posix_account USING btree (id);


--
-- TOC entry 35 (OID 64639)
-- Name: groups_gid_upper; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX groups_gid_upper ON groups USING btree (upper((gid)::text));

ALTER TABLE groups CLUSTER ON groups_gid_upper;


--
-- TOC entry 48 (OID 64640)
-- Name: posix_account_gidnumber_upper; Type: INDEX; Schema: public; Owner: ldap
--

CREATE INDEX posix_account_gidnumber_upper ON posix_account USING btree (upper((gidnumber)::text));


--
-- TOC entry 36 (OID 64641)
-- Name: groups_gidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_gidnumber_key UNIQUE (gidnumber);


--
-- TOC entry 38 (OID 64643)
-- Name: groups_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT groups_id_key UNIQUE (id);


--
-- TOC entry 42 (OID 64645)
-- Name: ldap_entries_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY ldap_entries
    ADD CONSTRAINT ldap_entries_id_key UNIQUE (id);


--
-- TOC entry 46 (OID 64647)
-- Name: ldap_oc_mappings_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY ldap_oc_mappings
    ADD CONSTRAINT ldap_oc_mappings_id_key UNIQUE (id);


--
-- TOC entry 52 (OID 64649)
-- Name: posix_account_details_uidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account_details
    ADD CONSTRAINT posix_account_details_uidnumber_key UNIQUE (id);


--
-- TOC entry 50 (OID 64651)
-- Name: posix_account_uidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY posix_account
    ADD CONSTRAINT posix_account_uidnumber_key UNIQUE (uidnumber);


--
-- TOC entry 53 (OID 64653)
-- Name: samba_group_mapping_gidnumber_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY samba_group_mapping
    ADD CONSTRAINT samba_group_mapping_gidnumber_key UNIQUE (gidnumber, id);


--
-- TOC entry 56 (OID 64655)
-- Name: samba_sam_account_id_key; Type: CONSTRAINT; Schema: public; Owner: ldap
--

ALTER TABLE ONLY samba_sam_account
    ADD CONSTRAINT samba_sam_account_id_key UNIQUE (id);


--
-- TOC entry 26 (OID 64391)
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('groups_id_seq', 105, true);


--
-- TOC entry 27 (OID 64403)
-- Name: institutes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('institutes_id_seq', 3, true);


--
-- TOC entry 28 (OID 64408)
-- Name: ldap_attr_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_attr_mappings_id_seq', 115, true);


--
-- TOC entry 29 (OID 64413)
-- Name: ldap_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_entries_id_seq', 1659, true);


--
-- TOC entry 30 (OID 64420)
-- Name: ldap_oc_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('ldap_oc_mappings_id_seq', 6, true);


--
-- TOC entry 31 (OID 64427)
-- Name: posix_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('posix_account_id_seq', 19, true);


--
-- TOC entry 32 (OID 64435)
-- Name: organizational_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('organizational_unit_id_seq', 6, true);


--
-- TOC entry 33 (OID 64445)
-- Name: samba_domain_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('samba_domain_id_seq', 1, false);


--
-- TOC entry 34 (OID 64453)
-- Name: samba_group_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ldap
--

SELECT pg_catalog.setval('samba_group_mapping_id_seq', 1, false);

