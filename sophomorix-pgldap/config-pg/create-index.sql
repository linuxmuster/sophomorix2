-- $Id$
\set AUTOCOMMIT off
BEGIN WORK;

CREATE INDEX leo_oc_name_idx ON ldap_entry_objclasses (oc_name);
--CREATE INDEX leo_id_idx ON ldap_entry_objclasses (id);
CREATE INDEX leo_entry_id_idx ON ldap_entry_objclasses (entry_id);
CREATE INDEX le_id_idx ON ldap_entries (id);
CREATE INDEX le_keyval_idx ON ldap_entries (keyval);
CREATE INDEX le_oc_map_id_idx ON ldap_entries (oc_map_id);
CREATE INDEX g_id_idx ON groups (id);
CREATE INDEX pa_id_idx on posix_account(id);

ANALYZE;

COMMIT WORK;
\set AUTOCOMMIT on
