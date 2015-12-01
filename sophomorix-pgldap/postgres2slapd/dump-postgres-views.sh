#!/bin/bash

LANG=C
export LANG

dump_dir=$1
mkdir -p $dump_dir

echo "   * Dumping userdata_view.sql to $dump_dir"
echo 'select * from userdata' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$ > $dump_dir/userdata_view.sql

echo "   * Dumping memberdata_view.sql to $dump_dir"
echo 'select * from memberdata' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$ > $dump_dir/memberdata_view.sql

echo "   * Dumping projectdata_view.sql to $dump_dir"
echo 'select * from projectdata' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$ > $dump_dir/projectdata_view.sql
echo "   * Dumping classdata_view.sql to $dump_dir"
echo 'select * from classdata' | psql -U postgres -d ldap | grep -v "\-\-+\-\-" | grep -v "rows)" | grep -v "Zeilen)" | grep -v ^$ > $dump_dir/classdata_view.sql
