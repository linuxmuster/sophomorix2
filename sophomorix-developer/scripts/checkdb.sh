#!/bin/bash

for id in `cat groups | awk '{print $1}'`; do 

  gname=`grep  "^ $id" groups  | awk -F"|" '{print $3}'`
  classdet=`psql -U ldap ldap -c "select count (*) from class_details where id='$id'" -P tuples_only` 
  if [ $classdet -eq 0 ]; then
    echo "CD:  group $id $gname existiert nicht in class_details"
    echo -n "Welche Objektart ist $gname? [l]ocalgroup [d]omaingroup
[r]oom :"
    read -n 1 tuep
    if [ $tuep = "l" ]; then
        echo "localgroup"
        sql="insert into class_details (id,quota,mailquota,mailalias,maillist,type) values ('$id','quota','-1','f','f','localgroup');"
        psql -U ldap ldap -c "$sql" 
        echo $sql
    fi
    if [ $tuep = "d" ]; then
        echo "domaingroup"
        sql="insert into class_details (id,quota,mailquota,mailalias,maillist,type) values ('$id','quota','-1','f','f','domaingroup');"
        psql -U ldap ldap -c "$sql" 
        echo $sql
    fi
    if [ $tuep = "r" ]; then
        echo "room"
        sql="insert into class_details (id,quota,mailquota,mailalias,maillist,type) values ('$id','quota','-1','f','f','room');"
        psql -U ldap ldap -c "$sql" 
        echo $sql
    fi
  fi

  psql -U ldap ldap -c "select count (*) from samba_group_mapping where id='$id'" -P tuples_only | grep "0"  > /dev/null 2>&1 && echo "SGM: group $id $gname existiert nicht in samba_group_mapping"

done


for host in `cat /etc/linuxmuster/workstations | awk -F";" '{print $2}'`; do

exam=`psql -U ldap ldap -c "select  count (*) from ldap_entries where dn like 'uid=$host,ou=accounts%'" -P tuples_only`
wsacc=`psql -U ldap ldap -c "select  count (*) from ldap_entries where dn like 'uid=$host$,ou=accounts%'" -P tuples_only`

if [ $exam -eq 1 ]; then
if [ $wsacc -eq 0 ]; then
echo "Kein WSACC für $host ! Deleting exam-account to fix..."
psql -U ldap ldap -c "DELETE from ldap_entries where dn like 'uid=$host,ou=accounts%'" 
fi
fi
done
 
