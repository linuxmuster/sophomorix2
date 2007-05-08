#!/bin/bash

echo 'select groups.gidnumber,gid,sambasid,sambagrouptype,displayname,description,sambasidlist from groups, samba_group_mapping where groups.id=samba_group_mapping.id;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$ > /tmp/groups.sql

echo 'SELECT * from samba_sam_account,posix_account where posix_account.id=samba_sam_account.id;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$  > /tmp/accounts.sql

#echo 'select groups.gid,memberuid from groups, groups_users WHERE groups_users.gidnumber=groups.gidnumber;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)"| grep -v ^$ > /tmp/groups_users.sql

echo 'select groups.gid,posix_account.uid,memberuidnumber from groups, groups_users, posix_account WHERE groups_users.gidnumber=groups.gidnumber AND posix_account.uidnumber=groups_users.memberuidnumber;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "Zeilen)" | grep -v "rows)" | grep -v ^$ > /tmp/groups_users.sql
