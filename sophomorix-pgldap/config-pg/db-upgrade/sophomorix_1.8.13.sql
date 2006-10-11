\set AUTOCOMMIT off
BEGIN WORK;

ALTER TABLE posix_account_details ADD usertoken character varying(255) NULL;
ALTER TABLE posix_account_details ADD scheduled_delete date NULL;

DROP VIEW userdata;

CREATE VIEW userdata AS
SELECT posix_account.id, posix_account.uidnumber, posix_account.uid,
posix_account.gidnumber, posix_account.firstname,
posix_account.surname, posix_account.homedirectory,
posix_account.gecos, posix_account.loginshell,
posix_account.userpassword, posix_account.description,
samba_sam_account.sambasid, samba_sam_account.cn,
samba_sam_account.sambalmpassword,
samba_sam_account.sambantpassword,
samba_sam_account.sambapwdlastset, samba_sam_account.sambalogontime,
samba_sam_account.sambalogofftime,
samba_sam_account.sambakickofftime,
samba_sam_account.sambapwdcanchange,
samba_sam_account.sambapwdmustchange,
samba_sam_account.sambaacctflags, samba_sam_account.displayname,
samba_sam_account.sambahomepath, samba_sam_account.sambahomedrive,
samba_sam_account.sambalogonscript,
samba_sam_account.sambaprofilepath,
samba_sam_account.sambauserworkstations,
samba_sam_account.sambaprimarygroupsid,
samba_sam_account.sambadomainname,
samba_sam_account.sambamungeddial,
samba_sam_account.sambabadpasswordcount,
samba_sam_account.sambabadpasswordtime,
samba_sam_account.sambapasswordhistory,
samba_sam_account.sambalogonhours,
posix_account_details.schoolnumber, posix_account_details.unid,
posix_account_details.exitunid, posix_account_details.birthname,
posix_account_details.title, posix_account_details.gender,
posix_account_details.birthday,
posix_account_details.birthpostalcode,
posix_account_details.birthcity, posix_account_details.denomination,
posix_account_details."class", posix_account_details.adminclass,
posix_account_details.exitadminclass,
posix_account_details.subclass, posix_account_details.creationdate,
posix_account_details.tolerationdate,
posix_account_details.deactivationdate,
posix_account_details.sophomorixstatus,
posix_account_details.accountstatus, posix_account_details.quota,
posix_account_details.mailquota,
posix_account_details.firstpassword,
posix_account_details.internetstatus,
posix_account_details.emailstatus, posix_account_details.lastlogin,
posix_account_details.lastgid, posix_account_details.classentry,
posix_account_details.schooltype,
posix_account_details.chiefinstructor,
posix_account_details.nationality,
posix_account_details.religionparticipation,
posix_account_details.ethicsparticipation,
posix_account_details.education, posix_account_details.occupation,
posix_account_details.starttraining,
posix_account_details.usertoken,
posix_account_details.scheduled_delete,
posix_account_details.endtraining, groups.gid FROM (((posix_account
FULL JOIN samba_sam_account ON ((posix_account.id =
samba_sam_account.id))) FULL JOIN posix_account_details ON
((posix_account_details.id = posix_account.id))) FULL JOIN groups ON
((posix_account.gidnumber = groups.gidnumber))) WHERE
((posix_account.uid)::text <> 'NextFreeUnixId'::text);

COMMIT WORK;
\set AUTOCOMMIT on
