#!/bin/bash

LANG=C
export LANG

dump_dir=$1
mkdir -p $dump_dir

echo "   * Dumping groups.sql to $dump_dir"
echo 'select groups.gidnumber,gid,sambasid,sambagrouptype,displayname,description,sambasidlist from groups, samba_group_mapping where groups.id=samba_group_mapping.id;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$ > $dump_dir/groups.sql

echo "   * Dumping accounts.sql to $dump_dir"
echo 'SELECT * from samba_sam_account,posix_account where posix_account.id=samba_sam_account.id;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$  > $dump_dir/accounts.sql

#echo 'select groups.gid,memberuid from groups, groups_users WHERE groups_users.gidnumber=groups.gidnumber;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)"| grep -v ^$ > /tmp/groups_users.sql

echo "   * Dumping groups_users.sql to $dump_dir"
echo 'select groups.gid,posix_account.uid,memberuidnumber from groups, groups_users, posix_account WHERE groups_users.gidnumber=groups.gidnumber AND posix_account.uidnumber=groups_users.memberuidnumber;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "Zeilen)" | grep -v "rows)" | grep -v ^$ > $dump_dir/groups_users.sql

echo "   * Appending dump of primary groups to $dump_dir"
echo 'select groups.gid,uid,uidnumber from groups,posix_account WHERE groups.gidnumber=posix_account.gidnumber;' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "Zeilen)" | grep -v "rows)" | grep -v ^$ >> $dump_dir/groups_users.sql

