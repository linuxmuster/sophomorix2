-- $Id$
\set AUTOCOMMIT off
BEGIN WORK;

CREATE INDEX idx_leo_oc_name ON ldap_entry_objclasses (oc_name);

COMMIT WORK;
\set AUTOCOMMIT on
