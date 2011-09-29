#!/bin/bash
#
#  Dieses Skript testet die ldap-postgres DB der Linux Musterlösung auf
#  fehlende Gruppeneinträge in den Tabellen
#   
#   class_details
#   samba_group_mapping
#  
#  - Problem am AEG Reutlingen Schuljahreswechsel  Sommer 2011
#  - Ticket I-182762  der Hotline (?)
#
#  GPLv2 Frank Schiebel (frank@linuxmsuter.net) 
#


# Ermitteln aller Gruppeni-IDs in der Datenbanktabelle groups
group_ids=`psql -U ldap ldap -c "select * from groups;" --tuples-only | awk -F"|" '{print $1}' | grep -v '^$' | sed -e 's/^ //'`

# Untersuche jede Gruppe
for id in $group_ids; do 
 
  # Um sinnvolle Ausgaben zu ermöglichen: Gruppenname zur ID ermitteln
  gname=`psql -U ldap ldap -c "select gid from groups where id='$id'" -P tuples_only | grep -v '^$' | sed -e 's/^ //'` 
  echo "checking group: $gname..."

  # Hier werden die zur ID der Gruppe gehörenden Einträge in der Tabelle class_details
  # gezählt - wenn da Null (0) zurückkommt, gibt es für diese Gruppe keinen Eintrag in
  # class_details, was auf einen Fehler hindeutet
  classdet=`psql -U ldap ldap -c "select count (*) from class_details where id='$id'" -P tuples_only` 
  echo "   $gname ($id) hat $classdet Einträge in class_details..."
  if [ $classdet -eq 0 ]; then
    echo "CD:  group $id $gname existiert nicht in class_details ###################################"
    
    # Reparaturversuch nur dann, wenn als Argument des Skriptes "repair" mitgegeben wurde
    ####################################################
    if [ $repair -eq "repair" ]; then
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
    ##########################################################
  fi

  # Hier werden die zur ID der Gruppe gehörenden Einträge in der Tabelle samba_group_mapping
  # gezählt - wenn da Null (0) zurückkommt, gibt es für diese Gruppe keinen Eintrag in
  # samba_group_mapping, was auf einen Fehler hindeutet
  sgm=`psql -U ldap ldap -c "select count (*) from samba_group_mapping where id='$id'" -P tuples_only`
  echo "   $gname ($id) hat $sgm Einträge in samba_group_mapping..."

  if [ $sgm -eq 0 ]; then
    echo "SGM: group $id $gname existiert nicht in samba_group_mapping ***********************************"
    # Hier gibt es von mir noch keinen Reparaturplan, sondern nur die Info, dass 
    # da ein Problem sein könnte
  fi

done

# Dieser Teil des Skripts bezieht sich aufProbleme beim Workstations import, das kann man 
# im Ersten Schritt zum Testen einfach mal weglasisen. Außerdem ist es nicht sehr zuverlässig, 
# weil es 
# a) nur workstations findet, keine User deren Gruppeneintrag in class_details fehlt
# b) auch nur die Hosts findet, die in der workstations Datein stehen. Wenn diese zum Probieren geändert wurde läuft der Teil des
# Skriptes ins Leere  
#for host in `cat /etc/linuxmuster/workstations | awk -F";" '{print $2}'`; do
#
#exam=`psql -U ldap ldap -c "select  count (*) from ldap_entries where dn like 'uid=$host,ou=accounts%'" -P tuples_only`
#wsacc=`psql -U ldap ldap -c "select  count (*) from ldap_entries where dn like 'uid=$host$,ou=accounts%'" -P tuples_only`
#
#if [ $exam -eq 1 ]; then
#if [ $wsacc -eq 0 ]; then
#echo "Kein WSACC für $host ! Deleting exam-account to fix..."
#psql -U ldap ldap -c "DELETE from ldap_entries where dn like 'uid=$host,ou=accounts%'" 
#fi
#fi
#done
# 
