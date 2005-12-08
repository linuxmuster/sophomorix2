#!/usr/bin/perl -w
# Dieses Modul (SophomorixPgLdap) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

package Sophomorix::SophomorixPgLdap;
require Exporter;
@ISA =qw(Exporter);
@EXPORT = qw(show_modulename
             db_connect
             db_disconnect
             check_connections
	     create_user_db_entry
             date_perl2pg
             date_pg2perl
             create_class_db_entry
             remove_class_db_entry
             pg_adduser
             pg_remove_all_secusers
             pg_get_group_list
             pg_get_adminclasses
             set_sophomorix_passwd
             user_deaktivieren
             user_reaktivieren
	     update_user_db_entry
	     remove_user_db_entry
             create_project_db
             get_sys_users
             get_teach_in_sys_users
             get_print_data
             search_user
             backup_user_database
             get_first_password
             check_sophomorix_user
             show_project_list
             get_smb_sid
);
# deprecated:             move_user_db_entry
#                         move_user_from_to
#                         show_class_list


# ??????????
# here i dont need to say Sophomorix::SophomorixBase::titel
# as in SophomorixSYSFiles. Whats wrong?
use Sophomorix::SophomorixBase qw ( titel
                                    do_falls_nicht_testen
                                    provide_class_files
                                    print_user_samba_data
                                    get_user_history
                                    print_forward
                                  );

use Crypt::SmbHash;


# ===========================================================================
# Loading the sys-db-Module, list of functions
# ===========================================================================
# list of functions to load if sys_db is 'files'
use if ${DevelConf::sys_db} eq 'files' , 
    'Sophomorix::SophomorixSYSFiles' => qw( add_class_to_sys
                                            get_user_auth_data
                                          );

use if ${DevelConf::sys_db} eq 'pgldap' , 
    'Sophomorix::SophomorixSYSPgLdap' => qw( add_class_to_sys
                                            get_user_auth_data
                                          );


=head1 Documentation of SophomorixPgLdap.pm

=head2 FUNCTIONS


=cut


sub show_modulename {
#    if($Conf::log_level>=2){
       &Sophomorix::SophomorixBase::titel("DB-Backend-Module:   SophomorixPgLdap.pm");
#   }
}



# connect to sql database
sub db_connect {
    my $dbname="ldap";
    my $dbuser="postgres";
    # password not needed because of postgres configuration
    # in pg_hba.conf pg_ident.conf
    my $pass_saved="";
    if($Conf::log_level>=3){
       print "Connecting to database ...\n";
    }
    # needs at UNIX sockets:   local all all  trust sameuser
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$dbuser","$pass_saved",
               { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    if (defined $dbh){
       if($Conf::log_level>=3){
          print "   Connection with password $pass_saved successful!\n";
          print "   Database $dbname ready for user $dbuser!\n";
       }
    } else {
       print "   Could not connect to database with password $pass_saved!\n";
    }
    return $dbh
}


# connect to sql database
sub db_disconnect {
    my ($dbh) = @_;
    $dbh->disconnect();
    print "Disconnecting ...\n";
}




sub check_connections {
    # check postgres and slapd. exit when they are not running
    # postgres
    my $dbname="ldap";
    my $dbuser="ldap";
    my $pass_saved="";
    # needs at UNIX sockets:   local all all  trust sameuser
    if($Conf::log_level>=3){
       print "   Checking postgres connection... \n";
    }
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$dbuser","$pass_saved",
              { RaiseError => 1, PrintError => 1});

    # ldap
    if($Conf::log_level>=3){
       print "   Checking ldap connection... \n";
    }
    my $ldap = Net::LDAP->new( '127.0.0.1' ) or die "$@";
}






# adds a user to the user database
sub create_user_db_entry {
    my $sql="";

    # prepare data
    my $today=`date +%d.%m.%Y`;
    chomp($today);
    my $today_pg=&date_perl2pg($today);
 
    my ($nachname,
       $vorname,
       $birthday_perl,
       $admin_class,
       $login,
       $pass,
       $sh,
       $quota,
       $unid,
       $unix_epoc,
       $pg_timestamp,
       $sophomorix_status,
       $id_force,
       $homedir_force) = @_;

    if (not defined $pg_timestamp){
       $pg_timestamp=$today_pg;
    }
    if (not defined $sophomorix_status){
       $sophomorix_status="U";
    }

    my $gecos = "$vorname"." "."$nachname";
    my $homedir="";
    if ($admin_class eq ${DevelConf::teacher}){
        # teachers
        $homedir = "${DevelConf::homedir_teacher}/$login";
    } else {
        # students
        $homedir = "${DevelConf::homedir_pupil}/$admin_class/$login";
    }

    if (defined $homedir_force){
        $homedir=$homedir_force;
    }

    my $description="perl: create_user_db_entry";
    my $birthday_pg = &date_perl2pg($birthday_perl);

    # create crypt password for liux
    my $crypt_salt_format = '%s';
    my $salt = sprintf($crypt_salt_format,make_salt());
    my $linux_pass = "{CRYPT}" . crypt($pass,$salt);
    # create crypted passwords for samba
    my ($lmpassword,$ntpassword) = ntlmgen $pass;
    if($Conf::log_level>=3){
       print "Encrypted Password $pass : \n";
       print "   Samba NT: $ntpassword \n";
       print "   Samba LM: $lmpassword \n";
       print "   Linux   : $linux_pass \n";
    }

    my $dbh=&db_connect();

    if ($DevelConf::testen==0) {


       $sql="SELECT manual_create_ldap_for_account('$login')";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       my $posix_account_id = $dbh->selectrow_array($sql);
       if($Conf::log_level>=3){
          print "   --> \$posix_account_id ist $posix_account_id \n\n";
       }

       #Freie UID holen
       $sql="select manual_get_next_free_uid()";
       if($Conf::log_level>=3){
          print "SQL: $sql\n";
       }
       my $uidnumber = $dbh->selectrow_array($sql);
       if (defined $id_force){
           # force the id if given as parameter
	   $uidnumber=$id_force;
       }
       if($Conf::log_level>=3){
          print "   --> \$uidnumber ist $uidnumber \n\n";
       }

       # neue gruppe anlegen und gidnumber holen, falls erforderlich
       my $gidnumber=&create_class_db_entry($admin_class);

       # get_sid
       my $sid = &get_smb_sid();
       # smb user sid
       my $user_sid = &smb_user_sid($uidnumber,$sid);
       print "USER-SID:        $user_sid\n";
       # smb group sid
       my $group_sid = &smb_group_sid($gidnumber,$sid);
       print "GROUP-SID:       $group_sid\n";

       my $smb_homepath="\\\\\\\\server\\\\$login";

       # User anlegen
       # 1. Tabelle posix_account
       # Pflichtfelder (laut Datenbank): id,uidnumber,uid,gidnumber,firstname

       $sql="INSERT INTO posix_account 
	  (id,uidnumber,uid,gidnumber,firstname,surname,
           homedirectory,gecos,loginshell,userpassword,description)
	  VALUES
	   ($posix_account_id,
            $uidnumber,
           '$login',
            $gidnumber,
           '$vorname',
           '$nachname',
           '$homedir',
           '$gecos',
           '$sh',
           '$linux_pass',
           '$description')";
        if($Conf::log_level>=3){
           print "SQL: $sql\n";
        }
        $dbh->do($sql);

       # 2. Tabelle samba_sam_account
       # Pflichtfelder (laut Datenbank): id
       $sql="INSERT INTO samba_sam_account
	 (id,sambasid,cn,sambalmpassword,sambantpassword,
          sambapwdlastset,sambalogontime,sambalogofftime,sambakickofftime,
          sambapwdcanchange,sambapwdmustchange,sambaacctflags,
          displayname,sambahomepath,sambahomedrive,sambalogonscript,
          sambaprofilepath,description,sambauserworkstations,
          sambaprimarygroupsid,sambadomainname,sambamungeddial,
          sambabadpasswordcount,sambabadpasswordtime,
          sambapasswordhistory,sambalogonhours)
	VALUES
	($posix_account_id,
         '$user_sid',
         NULL,
         '$lmpassword',
         '$ntpassword',
         '$unix_epoc',
         '0',
         '2147483647',
         '2147483647',
         '0',
         '2147483647',
         '[UX]',
         '$gecos',
         '$smb_homepath',
         'H:',
         NULL,
         NULL,
         NULL,
         NULL,
         '$group_sid',
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
        )
	";
       if($Conf::log_level>=3){
          print "SQL: $sql\n";
       }
       $dbh->do($sql);

       # 3. Tabelle posix_account_details
       # Pflichtfelder (laut Datenbank); id

       $sql="INSERT INTO posix_account_details
	   ( id,schoolnumber,unid,adminclass,exitadminclass,subclass,
             creationdate,sophomorixstatus,quota,firstpassword,
             birthname,title,gender,birthday,birthpostalcode,
             birthcity,denomination,class,classentry,schooltype,
             chiefinstructor,nationality,religionparticipation,
             ethicsparticipation,education,occupation,
             starttraining,endtraining)
	 VALUES
	  ($posix_account_id,
           1,
           '$unid',
           '$admin_class',
           '',
           '',
           '$pg_timestamp',
           '$sophomorix_status',
           '$quota',
           '$pass',
           '',
           '',
           '', 
           '$birthday_pg',
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           TRUE,
           FALSE,
           '',
           '',
           '19700101',
           '19700101')";
      if($Conf::log_level>=3){
         print "SQL: $sql\n";
      }
      $dbh->do($sql);
      $dbh->disconnect();
  } else {
      if($Conf::log_level>=3){
         print "Test:   Wrote entry into database\n";
      }
  }
}




=pod

=item I<set_sophomorix_passwd(login,string)>

Setzt das Passwort string in linux, samba, ...

=cut

sub set_sophomorix_passwd {
    my ($login,$pass) = @_;
       # create crypt password for liux
       my $crypt_salt_format = '%s';
       my $salt = sprintf($crypt_salt_format,make_salt());
       my $linux_pass = "{CRYPT}" . crypt($pass,$salt);
       # create crypted passwords for samba
       my ($lmpassword,$ntpassword) = ntlmgen $pass;
       my $dbh=&db_connect();
       my $sql="";
       $sql="SELECT id FROM userdata WHERE uid='$login'";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       my ($id)= $dbh->selectrow_array($sql);
    if (not defined $id){
       $id="";
       print "ERROR: User $login not found in database to set password!\n";
       $return=0;
    } else {

       if($Conf::log_level>=2){
          print "Setting password of user $login (Database ID: $id)...\n";
       }
       $sql="UPDATE posix_account SET userpassword='$linux_pass' 
            WHERE id = $id";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       if ($DevelConf::testen==0) {
          $dbh->do($sql);
       } else {
          print "Test: setting password part 1\n";
       }
       # todo sambapwlastset  ????????? 
       $sql="UPDATE samba_sam_account 
              SET sambalmpassword='$lmpassword', sambantpassword='$ntpassword'
              WHERE id = $id";
       if($Conf::log_level>=3){
          print "SQL: $sql\n";
       }
       if ($DevelConf::testen==0) {
          $dbh->do($sql);
      } else {
          print "Test: setting password part 2\n";
      }
    }

    $dbh->disconnect();
}





sub make_salt {
   my $length=32;
   $length = $_[0] if exists($_[0]);

   my @tab = ('.', '/', 0..9, 'A'..'Z', 'a'..'z');
   return join "",@tab[map {rand 64} (1..$length)];
}





# adds a class to the user database
sub create_class_db_entry {
    my ($class_to_add,$sub) = @_;
    my ($class,$dept,$type,$mail,$quota) = ("","","","","");
    if (not defined $sub){
        # standard: no subclass
	$sub=0;
        $type="adminclass";
    } elsif ($sub==0) {
        $type="adminclass";
    } elsif ($sub==2) {
        $type="project";
    } else {
        $type="subclass";
    }
    my %classes=();
    my $sql="";
    my $gidnumber;
    # SQL-Funktion aufrufen die Enträge in ldap_entries, ldap_entry_objclasses
    # und NextFreeUnixId macht und groups_id zurück gibt
    # der Username muss hier schon übergeben werden.
    my $dbh=&db_connect();

    # exists class already? 
    my ($gid_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$class_to_add'" );
    if (not defined $gid_sys){
       $gid_sys="";
    }

    # check if group exists
    if ($gid_sys ne ""){
        # gidnumber found
        $gidnumber=$gid_sys;
        print "group $class_to_add exists already ($gidnumber)\n";
    } else {
        # begin adding group
        print "group does not exist -> adding $class_to_add\n";

    #Freie GID holen
    $sql="select manual_get_next_free_gid()";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $gidnumber = $dbh->selectrow_array($sql);
    print "Received $gidnumber as next free gidnumber\n";
    $sql="SELECT manual_create_ldap_for_group('$class_to_add')";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my $groups_id = $dbh->selectrow_array($sql);

    #Gruppe anlegen (2Tabellen)
    #1. Tabelle groups
    #Pflichtfelder (laut Datenbank): alle

    $sql="INSERT INTO groups
         (id,gidnumber,gid)
	 VALUES
	 ($groups_id,$gidnumber,'$class_to_add')";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);

    # get_sid
    my $sid = &get_smb_sid();

    # smb group sid
    my $group_sid = &smb_group_sid($gidnumber,$sid);

    #2. Tabelle samba_group_mapping
    #Pflichtfelder (laut Datenbank) id
    # sambagrouptype (2=domaingroup(defaultgroup), 4=localgroup, 5=builtingroup)
    $sql="INSERT INTO samba_group_mapping
	 (id,gidnumber,sambasid,sambagrouptype,displayname,description,sambasidlist)
	 VALUES
	 ($groups_id,
          $gidnumber,
          '$group_sid',
          '2',
          '$class_to_add',
          NULL,
          NULL)";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);


    if ($sub==1){
        # adding a subclass
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,schooltype,department,mailalias,type)
	    VALUES
  	    ($groups_id,
             NULL,
             '',
             '',
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);

    } elsif ($sub==2){
        # adding a project
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,schooltype,department,mailalias,type)
	    VALUES
  	    ($groups_id,
             NULL,
             '',
             '',
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);


    } else {
        # adding a adminclass
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,schooltype,department,mailalias,type)
	    VALUES
  	    ($groups_id,
             'quota',
             '',
             '',
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    }
    
    } # end adding group
    return $gidnumber;
}



# adds a class to the user database
sub remove_class_db_entry {
   # todo ????????????????

}



sub pg_adduser {
    # add a user to a group
    my ($user,$group) = @_;
    my $sql="";
    my $dbh=&db_connect();

    $sql="SELECT uidnumber FROM userdata WHERE uid='$user'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($uidnumber)= $dbh->selectrow_array($sql);

    $sql="SELECT gidnumber FROM classdata WHERE gid='$group'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($gidnumber)= $dbh->selectrow_array($sql);

    if($Conf::log_level>=2){
       print "   User $user has id  $uidnumber\n";
       print "   Group $group has id  $gidnumber\n";
       print "   Adding user $uidnumber to group $gidnumber\n";
    }

    print "Adding user $user to group $group\n";
    # todo ??????? make sure entry doesnt exist
    $sql="INSERT INTO groups_users VALUES ($gidnumber,$uidnumber);";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
}


sub pg_remove_all_secusers {
    # remove users from a group (only secondary memberships) 
    my ($group) = @_;
    my $sql="";
    my $dbh=&db_connect();

    $sql="SELECT gidnumber FROM classdata WHERE gid='$group'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($gidnumber)= $dbh->selectrow_array($sql);
    if($Conf::log_level>=2){
       print "   Removing $group with id  $gidnumber\n";
    }
    $sql="DELETE FROM groups_users WHERE gidnumber='$gidnumber'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
}



sub pg_get_group_list {
    my ($user) = @_;
    my $sql="";
    my @grp_list=();
    my $dbh=&db_connect();

    $sql="SELECT gid,uidnumber FROM userdata WHERE uid='$user'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($gid,$uidnumber)= $dbh->selectrow_array($sql);

    push @grp_list, $gid;

    my $sth= $dbh->prepare( "SELECT userdata.uid,groups.gid 
                             FROM groups_users,userdata,groups 
                             WHERE groups_users.memberuid=userdata.uidnumber 
                               AND groups_users.gidnumber=groups.gidnumber
                               AND userdata.uid='$user'
                             ORDER BY groups.gid" );
      $sth->execute();

    my $array_ref = $sth->fetchall_arrayref();

    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $sec_gid=${$array_ref}[$i][1];
        push @grp_list, $sec_gid;
        $i++;
    }   

    return @grp_list;
}


sub pg_get_adminclasses {
    # fetch all entries with type adminclasses
    my ($group) = @_;
    my %classes=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid from classdata WHERE type='adminclass'" );
      $sth->execute();

    my $array_ref = $sth->fetchall_arrayref();

    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        $classes{$gid}="";
        $i++;
    }   
    return %classes;
}



###########################################################################
# CHECKED, NEW
###########################################################################



# convert dates from 1988-12-01 to 01.12.1988
sub date_pg2perl {
    my ($string) = @_;
    if (not defined $string){
	$string="";
    }
    my $perl="";
    if ($string ne ""){
       my ($year,$month,$day)=split(/-/,$string);
       $perl="$day"."."."$month"."."."$year";
   }
    return $perl;
}



# convert dates from 01.12.1988 to 1988-12-01
sub date_perl2pg {
    my ($string) = @_;
    my $pg="";
    if ($string ne ""){
       my ($day,$month,$year)=split(/\./,$string);
       $pg="$year"."-"."$month"."-"."$day";
    } else {
        # what should be saved, when nothing should be saved
#	$pg="3333-03-03";
	$pg="NULL";
    }
    return $pg;
}


# reads the user database into perl hashes.
# the scripts all work with the perl hashes (instead of the database itself)
sub get_sys_users {
   my $number=1;

   # Result-hashes
   my %identifier_adminclass=();
   my %identifier_login=();  
   my %identifier_subclass=();
   my %identifier_status=();
   my %identifier_toleration_date=();
   my %identifier_deactivation_date=();
   my %unid_identifier=();
   my %identifier_exit_adminclass=();
   my %identifier_account_type=();

my $dbh=&db_connect();


# select the columns that i need
my $sth= $dbh->prepare( "SELECT uid, firstname, surname, birthday, adminclass, exitadminclass, unid, subclass, tolerationdate, deactivationdate, sophomorixstatus FROM userdata" );
$sth->execute();

my $array_ref = $sth->fetchall_arrayref();

foreach my $row (@$array_ref){
    # split the array, to give better names
    # or use numbers and look in the SELECT statement
    my $account_type="",

    my ($login,
        $firstname,
        $surname,
        $birthday_pg,
        $admin_class,
        $exit_admin_class,
        $unid,
        $subclass,
        $toleration_date_pg,
        $deactivation_date_pg,
        $status,
        ) = @$row;


   # date strings must be defined
   if (not defined $toleration_date_pg){
       $toleration_date_pg="";
   }
   if (not defined $deactivation_date_pg){
       $deactivation_date_pg="";
   }


   # exclude one user ????????ß
   if ($login eq "NextFreeUnixId"){
       next;
   }       

#    print "\nEntry:   @{ $row }\n";   # todo


    my $birthday = &date_pg2perl($birthday_pg);
    my $toleration_date = &date_pg2perl($toleration_date_pg);
    my $deactivation_date = &date_pg2perl($deactivation_date_pg);

    my $identifier=join("",
         ($surname,";",
          $firstname,";",
          $birthday));

   # print what was selected
   if($Conf::log_level>=3){
      print "\n";
      print "User $number  Attributes (MUST): \n";
      print "  Login       :   $login \n"; 
      print "  AdminClass  :   $admin_class \n";
      print "  Birthday(pg):   $birthday_pg \n";
      print "  Birthday(pl):   $birthday \n";
      print "  Identifier  :   $identifier \n";

      print "User Attributes (MAY): \n";

      # unid is optional
      if ($unid ne "") {
         print "  Unid              :   $unid \n" ;
      } else {
         print "  Unid              :   --- \n" ;
      }

      # subclass is optional
      if ($subclass ne "") {
         print "  SubClass          :   $subclass \n" ;
      } else {
         print "  SubClass          :   --- \n" ;
      }

      # Status
      if ($status ne "") {
         print "  Status            :   $status \n" ;
      } else {
         print "  Status            :   --- \n" ;
      }

      # TolerationDate is optional
      if ($toleration_date ne "") {
         print "  TolerationDate    :   $toleration_date \n" ;
      } else {
         print "  TolerationDate    :   --- \n" ;
      }

      # DeactivationDate is optional
      if ($deactivation_date ne "") {
         print "  DeactivationDate  :   $deactivation_date \n" ;
      } else {
         print "  DeactivationDate  :   --- \n" ;
      }

      # ExitAdminClass is optional
      if ($exit_admin_class ne "") {
         print "  ExitAdminClass    :   $exit_admin_class \n" ;
      } else {
         print "  ExitAdminClass    :   --- \n" ;
      }

      # AccountType is optional
      if ($account_type ne "") {
         print "  AccountType       :   $account_type \n" ;
      } else {
         print "  AccountType       :   --- \n" ;
      }

          print "\n";
   }# end loglevel

   # In Hash schreiben: mit Klasse als Wert (um Versetzen herauszufinden)
#   $schueler_im_system_hash{$identifier}="$admin_class";
   # In Hash schreiben: mit loginnamen als Wert (um Löschen herauszufinden)
#   $schueler_im_system_loginname{$identifier}="$login";
   # In Hash schreiben: mit Zeile als Wert (beim Löschen zu entfernen)
#   $schueler_im_system_protokoll_linie{$identifier}="$_";

   if (not defined $unid){$unid=""}
   if (not defined $subclass){$subclass=""}
   if (not defined $status){$status=""}
   if (not defined $toleration_date){$toleration_date=""}
   if (not defined $deactivation_date){$deactivation_date=""}
   if (not defined $admin_class){$admin_class=""}
   if (not defined $exit_admin_class){$exit_admin_class=""}
   if (not defined $account_type){$account_type=""}

   # add the user to the hashes
   $identifier_adminclass{$identifier} = "$admin_class";
   $identifier_login{$identifier} = "$login";
   $identifier_status{$identifier} = "$status";

   # unid is optional
   if ($unid ne "") {        
      $unid_identifier{$unid} = "$identifier";
   }

   # subclass is optional
   if ($subclass ne "") {        
      $identifier_subclass{$identifier} = "$subclass";
   }

   # TolerationDate is optional
   if ($toleration_date ne "") {        
      $identifier_toleration_date{$identifier} = "$toleration_date";
   }

   # DeactivationDate is optional
   if ($deactivation_date ne "") {        
      $identifier_deactivation_date{$identifier} = "$deactivation_date";
   }

   # ExitAdminClass is optional
   if ($exit_admin_class ne "") {        
      $identifier_exit_adminclass{$identifier} = "$exit_admin_class";
   }

   # AccountType is optional
   if ($account_type ne "") {        
      $identifier_account_type{$identifier} = "$account_type";
   }


   # increase counter for users
   $number++;

}

    $dbh->disconnect();

   # returns some Hashes, as a list
   # 1:  identifier - login
   # 2:  identifier - sophomorixAdminClass
   # 3:  identifier - sophomorixStatus
   # 4:  identifier - sophomorixSubClass
   # 5:  identifier - sophomorixTolerationDate
   # 6:  identifier - sophomorixDeaktivationDate
   # 7:  unid - sophomorixIdentifier
   return(\%identifier_login, 
          \%identifier_adminclass, 
          \%identifier_status,
          \%identifier_subclass,
          \%identifier_toleration_date,
          \%identifier_deactivation_date,
          \%unid_identifier,
          \%identifier_exit_adminclass,
          \%identifier_account_type
         );
}




# returns a list of users with status D,T,S,A
# i.e. the users for  teach-in
sub get_teach_in_sys_users {
   my @toleration=();
   my $dbh=&db_connect();

   # select the columns that i need
   my $sth= $dbh->prepare( "SELECT uid, firstname, surname, 
                                   birthday, sophomorixstatus 
                            FROM userdata 
                            WHERE sophomorixstatus='T' 
                               OR sophomorixstatus='S' 
                               OR sophomorixstatus='D' 
                               OR sophomorixstatus='A'" );
   $sth->execute();

   my $array_ref = $sth->fetchall_arrayref();

   foreach my $row (@$array_ref){
       # split the array, to give better names
       my $identifier="";
       my ($login,
           $first,
           $last,
           $birth,
           $status)=@$row;

       my $birthday_perl = &date_pg2perl($birth);

       $identifier=$last.";".$first.";".$birthday_perl;
       push @toleration, $identifier;

   }
   return @toleration;
}




# returns a list of the following lines from all users:
# Syntax:
#   class;firstname lastname;loginname;FirstPassword;birthday;  

sub get_print_data {
    my @lines=();

    my $dbh=&db_connect();

    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uid, firstname, 
                                    surname, birthday, 
                                    adminclass, firstpassword 
                             FROM userdata" );
$sth->execute();

my $array_ref = $sth->fetchall_arrayref();

foreach my $row (@$array_ref){
    # split the array, to give better names

    my ($login,
        $firstname,
        $surname,
        $birthday_pg,
        $admin_class,
        $firstpass,
        ) = @$row;

    my $birthday = &date_pg2perl($birthday_pg);

    # assemble string
    my $string="$admin_class".";".
               "$firstname $surname".";".
               "$login".";".
               "$firstpass".";".
               "$birthday".";"."\n";    

    push @lines, $string;

}
    return @lines;
}


=head1 update_user_db_entry

Parameter 1: Loginname of user to be updated

Parameter 2: List with Attribute=Value

=cut

# this function changes the fields of the user login

sub update_user_db_entry {
    my $login=shift;
    my $admin_class="";
    my $gid_name="";
    my $gid_number;
    my $home_dir="";
    my $lastname="";
    my $firstname="";
    my $gecos="";
    my $first_pass="";
    my $birthday="";
    my $unid="";
    my $exitunid="";
    my $subclass="";
    my $status="";
    my $toleration_date="",
    my $deactivation_date="";
    my $exit_admin_class="";
    my $account_type="";
    my $quota="";

    my @posix=();
    my @posix_details=();
    my @samba=();
  
    my $dbh=&db_connect();
    my $sql="";
    
    # Check of Parameters
    foreach my $param (@_){
       ($attr,$value) = split(/=/,$param);
       if($Conf::log_level>=2){
          printf "   %-18s : %-20s\n",$attr ,$value;
       }
       if    ($attr eq "AdminClass"){
	   $admin_class="$value";
	   push @posix_details, "adminclass = '$admin_class'";
       }
       elsif ($attr eq "Name"){
           $firstname="$value";
	   push @posix, "firstname = '$firstname'";
       }
       elsif ($attr eq "LastName"){
           $lastname="$value";
	   push @posix, "surname = '$lastname'";
       }
       elsif ($attr eq "Gecos"){
           $gecos="$value";
	   push @posix, "gecos = '$gecos'";
	   push @samba, "displayname = '$gecos'";
       }
       elsif ($attr eq "FirstPass"){
           $first_pass="$value";
	   push @posix_details, "firstpassword = '$first_pass'";
       }
       elsif ($attr eq "Birthday"){
           $birthday = &date_perl2pg($value);
	   push @posix_details, "birthday = '$birthday'";
       }
       elsif ($attr eq "Unid"){
           $unid="$value";
	   push @posix_details, "unid = '$unid'";
       }
       elsif ($attr eq "ExitUnid"){
           $exit_unid="$value";
	   push @posix_details, "exitunid = '$exit_unid'";
       }
       elsif ($attr eq "SubClass" or $attr eq "Subclass"){
           $subclass="$value";
	   push @posix_details, "subclass = '$subclass'";
       }
       elsif ($attr eq "Status"){
           $status="$value";
	   push @posix_details, "sophomorixstatus = '$status'";
       }
       elsif ($attr eq "TolerationDate"){
           $toleration_date=&date_perl2pg($value);
           if ($toleration_date ne "NULL"){
	       $toleration_date="'".$toleration_date."'";
           }
	   push @posix_details, "tolerationdate = $toleration_date";
       }
       elsif ($attr eq "DeactivationDate"){
           $deactivation_date=&date_perl2pg($value);
           if ($deactivation_date ne "NULL"){
	       $deactivation_date="'".$deactivation_date."'";
           }
	   push @posix_details, "deactivationdate = $deactivation_date";
       }
       elsif ($attr eq "ExitAdminClass"){
           $exit_admin_class="$value";
           push @posix_details, "exitadminclass = '$exit_admin_class'";
           }
       elsif ($attr eq "Gid"){
           $gid_name="$value";
           print " ****adding $gid_name\n";
           # neue gruppe anlegen und gidnumber holen, falls erforderlich
           $gid_number=&create_class_db_entry($gid_name);
           # homedirectory
           if ($gid_name eq ${DevelConf::teacher}) {
              # in klasse lehrer versetzten
              $home_dir="${DevelConf::homedir_teacher}/${login}";
           } else {
              # in andere Klasse versetzten (auch dachboden/speicher)
              $home_dir="${DevelConf::homedir_pupil}/${gid_name}/${login}";
           } 
           # groupsid
           my $sid = &get_smb_sid();
           my $group_sid = &smb_group_sid($gid_number,$sid);
           # add to SQL
           push @posix, "gidnumber = '$gid_number'";
           push @posix, "homedirectory = '$home_dir'";
           push @samba, "sambaprimarygroupsid = '$group_sid'";
       }
       elsif ($attr eq "AccountType"){
           $account_type="$value";
           # todo
       }
       elsif ($attr eq "Quota"){
           $quota="$value";
           push @posix_details, "quota = '$quota'";
       }
       else {print "Attribute $attr unknown\n"}
    }



    $sql="SELECT id FROM userdata 
          WHERE uid='$login'";
    if($Conf::log_level>=3){
        print "\nSQL: $sql\n";
    }
    my ($id)=$dbh->selectrow_array($sql);
    if($Conf::log_level>=3){
       print "Retrieved Id of $login: $id \n";
    }

    # updating posix_account
    my $posix=join(", ",@posix);
    if ($posix ne ""){
       $sql="UPDATE posix_account
             SET 
              $posix
             WHERE id = $id
            ";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
       $dbh->do($sql);
    }

    # updating posix_account_details
    my $posix_details=join(", ",@posix_details);
    if ($posix_details ne ""){
       $sql="UPDATE posix_account_details
             SET 
              $posix_details
             WHERE id = $id
            ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       $dbh->do($sql);
    }
    # updating samba_sam_account
    my $samba=join(", ",@samba);
    if ($samba ne ""){
       $sql="UPDATE samba_sam_account
             SET 
              $samba
             WHERE id = $id
            ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       $dbh->do($sql);
    }
    $dbh->disconnect();

    # ??? besser was sinnvolles
    return 1;
}



# this function removes a user entry in the database 
sub remove_user_db_entry {
    my ($login) = @_;
    my $dbh=&db_connect();
    my $sql="";

    # what to do
    $sql="SELECT manual_delete_account('$login')";
    if($Conf::log_level>=3){
       print "SQL: $sql\n";
    }
    my $uidnumber = $dbh->selectrow_array($sql);
    print "Deleted User $login ($uidnumber)\n";

}


# ===========================================================================
# User DE-aktivieren
# ===========================================================================

# deactivate a users login, ...

sub user_deaktivieren {
   my ($login) = @_;
   if($Conf::log_level>=2){
      print "Deactivating $login ...\n";
   }

   # samba
   my $samba_string="smbpasswd -d $login >/dev/null";
   if($Conf::log_level>=2){
      print "   Disabling samba login of $login:  $samba_string\n";
   }
   system("$samba_string");

   # linux
   # fetch the old crypted password
   my $dbh=&db_connect();
   my $sql="";
   $sql="SELECT userpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($crypt_pass)= $dbh->selectrow_array($sql);
   print "   Unix password: $crypt_pass\n";

   if (not defined $crypt_pass){
       print "   User $login not found in database to disable unix-account!\n";
   } elsif ($crypt_pass=~m/!$/) {
       print "   Unix account of $login is already disabled!\n";
   } else {
       print "   Disabling unix account of $login!\n";
       # append ! to pasword
       $crypt_pass="$crypt_pass"."!";
       # replace password
       print "Replacing password with --$crypt_pass-- \n";
       $sql="UPDATE posix_account
             SET 
             userpassword = '$crypt_pass'
             WHERE uid = '$login'
            ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
          $dbh->do($sql);
 
   }
   &db_disconnect($dbh);
#   my $linux_string="usermod -L $login >/dev/null";
#   system("$linux_string");
   if($Conf::log_level>=2){
      print "Samba:  $samba_string\n";
    }
   # ToDo
   # mailabruf
   # ToDo
   # public:html : sperren
#   system  "chmod 0001 $www_home";  # gesperrt
   # Ende des Eintrags
   if($Conf::log_level>=2){
      print "\n";
    }
}





# ===========================================================================
# User RE-aktivieren
# ===========================================================================

# enables a users login, ...

sub user_reaktivieren {
   my ($login) = @_;
   if($Conf::log_level>=2){
      print "Reactivating $login ...\n";
   }

   # samba
   my $samba_string="smbpasswd -e $login >/dev/null";
   if($Conf::log_level>=2){
      print "   Enabling samba login of $login:  $samba_string\n";
   }
   system("$samba_string");

   # linux
   # fetch the old crypted password
   my $dbh=&db_connect();
   my $sql="";
   $sql="SELECT userpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($crypt_pass)= $dbh->selectrow_array($sql);
   if($Conf::log_level>=3){
      print "   Unix password: $crypt_pass\n";
   }

   if (not defined $crypt_pass){
       print "   User $login not found in database to enable unix-account!\n";
   } elsif (not $crypt_pass=~m/!/) {
       print "   Unix account of $login is already enabled!\n";
   } else {
       print "   Enabling unix account of $login!\n";
       # remove ! from pasword
       $crypt_pass=~s/!$//g;
       # replace password
       print "Replacing password with --$crypt_pass-- \n";
       $sql="UPDATE posix_account
             SET 
             userpassword = '$crypt_pass'
             WHERE uid = '$login'
            ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
          $dbh->do($sql);
 
   }
   &db_disconnect($dbh);

   # ToDo
   # mailabruf
   # ToDo
   # public:html:
      # NICHT entsperren
}





# create a project (can be implemented later)

sub create_project_db {
    # fist argument is options
    my $project=shift;

    my $sql="";

    my $create=0;
    my $param="";
#    my $login_file="";
    my $project_name_file="";
    my $old_line="";
    my $new_line="";
    my $count=0;
    my ($p_name,$p_long_name,$p_teachers,$p_members,$p_member_groups,
        $p_add_quota,$p_max_members)=(),

    my $file="${DevelConf::protokoll_pfad}/projects_db";

    foreach $param (@_){
       ($attr,$value) = split(/=/,$param);
       if ($attr eq "File"){$file="$value"}
       if ($attr eq "Create"){$create=1}
    } 


#####
    open(TMP, ">$file.tmp");
    open(FILE, "<$file");
    while(<FILE>){
        $old_line=$_;
	($project_name_file)=split(/;/);
#####


            # exists project
        if ($project eq $project_name_file){
           # found the line
	    chomp();
	    print "Project $project is an existing project -> UPDATING\n";
            printf "   %-18s : %-20s\n","Name" ,$project;
           ($p_name,$p_long_name,$p_teachers,$p_members,$p_member_groups,
            $p_add_quota,$p_max_members)=split(/;/);
           if (not defined $p_name){$p_name=$project}
           if (not defined $p_long_name){$p_long_name=$p_name}
           if (not defined $p_teachers){$p_teachers=""}
           if (not defined $p_members){$p_members=""}
           if (not defined $p_member_groups){$p_member_groups=""}
           if (not defined $p_add_quota){$p_add_quota=""}
           if (not defined $p_max_members){$p_max_members=""}
           $count++;
           # Check of Parameters
           foreach $param (@_){
              ($attr,$value) = split(/=/,$param);
              printf "   %-18s : %-20s\n",$attr ,$value;
              if    ($attr eq "Name"){$p_name="$value"}
              elsif ($attr eq "LongName"){$p_long_name="$value"}
              elsif ($attr eq "Teachers"){$p_teachers="$value"}
              elsif ($attr eq "Members"){$p_members="$value"}
              elsif ($attr eq "MemberGroups"){$p_member_groups="$value"}
              elsif ($attr eq "AddQuota"){$p_add_quota="$value"}
              elsif ($attr eq "MaxMembers"){$p_max_members="$value"}
              elsif ($attr eq "File"){$file="$value"}
              elsif ($attr eq "Create"){$create=1}
              else {print "Attribute $attr unknown\n"}
	  }



#####
          # change the Line
          $new_line=$p_name.";".$p_long_name.";".$p_teachers.";".
                    $p_members.";".$p_member_groups.";".$p_add_quota.";".
                    $p_max_members.";\n";
          print "OLD Line:   $old_line";
          print "NEW Line:   $new_line";
          print TMP "$new_line";         
#####^


        } else {
#####
            print TMP "$old_line";
#####^
        }
    }
    # new file is in *.tmp
    if ($count==1){
        # one line found -> updating the project
	close(FILE);
	close(TMP);
       system("mv $file.tmp $file");  
    } elsif ($count==0 and $create==1){ 



        # 0 lines found -> creating the project
        print "Project $project is nonexisting -> CREATING\n";
        $p_name=$project;
        printf "   %-18s : %-20s\n","Name" ,$project;
        foreach $param (@_){
           ($attr,$value) = split(/=/,$param);
           printf "   %-18s : %-20s\n",$attr ,$value;
           if ($attr eq "LongName"){$p_long_name="$value"}
           elsif ($attr eq "Teachers"){$p_teachers="$value"}
           elsif ($attr eq "Members"){$p_members="$value"}
           elsif ($attr eq "MemberGroups"){$p_member_groups="$value"}
           elsif ($attr eq "AddQuota"){$p_add_quota="$value"}
           elsif ($attr eq "MaxMembers"){$p_max_members="$value"}
           elsif ($attr eq "File"){$file="$value"}
           elsif ($attr eq "Create"){$create=1}
           else {print "Attribute $attr unknown\n"}
        }
        # Enough Information to create the Project?
        if (not defined $p_long_name){$p_long_name=$project}
        if (not defined $p_teachers){$p_teachers="root"}
        if (not defined $p_members){$p_members=""}
        if (not defined $p_member_groups){$p_member_groups=""}
        if (not defined $p_add_quota){$p_add_quota=""}
        if (not defined $p_max_members){$p_max_members="NULL"}

        # insert new project

        my $gidnumber=&create_class_db_entry($project,2);

        my $dbh=&db_connect();

        # fetching tha table id
        my ($id)= $dbh->selectrow_array( "SELECT id 
                                          FROM groups 
                                          WHERE gidnumber=$gidnumber" );

       $sql="INSERT INTO project_details 
	  (id,longname,teachers,members,membergroups,addquota,maxmembers)
	  VALUES
	   ($id,
           '$p_long_name',
           '$p_teachers',
           '$p_members',
           '$p_member_groups',
           '$p_add_quota',
            $p_max_members
          )";
        if($Conf::log_level>=3){
           print "SQL: $sql\n";
        }
        $dbh->do($sql);

        &db_disconnect($dbh);

        $new_line=$p_name.";".$p_long_name.";".$p_teachers.";".
                  $p_members.";".$p_member_groups.";".$p_add_quota.";".
                  $p_max_members.";\n";
        print "OLD Line:   $old_line";
        print "NEW Line:   $new_line";
        print TMP "$new_line";         
	close(FILE);
        close(TMP);
        system("mv $file.tmp $file");  
    } elsif ($count==0){
        print "Project $project is nonexisting -> I do nothing\n";
        print "Use --create to create the project\n";
    }
    return $count;
}





sub create_project_db_oldstuff {
    my $create=0;
    my $param="";
#    my $login_file="";
    my $project_name_file="";
    my $old_line="";
    my $new_line="";
    my $count=0;
    my ($p_name,$p_long_name,$p_teachers,$p_members,$p_member_groups,
        $p_add_quota,$p_max_members)=(),

    my $project=shift;
    my $file="${DevelConf::protokoll_pfad}/projects_db";

    # Which file?
    foreach $param (@_){
       ($attr,$value) = split(/=/,$param);
       if ($attr eq "File"){$file="$value"}
       if ($attr eq "Create"){$create=1}
    } 

    open(TMP, ">$file.tmp");
    open(FILE, "<$file");
    while(<FILE>){
        $old_line=$_;
	($project_name_file)=split(/;/);
        if ($project eq $project_name_file){
           # found the line
	    chomp();
	    print "Project $project is an existing project -> UPDATING\n";
            printf "   %-18s : %-20s\n","Name" ,$project;
           ($p_name,$p_long_name,$p_teachers,$p_members,$p_member_groups,
            $p_add_quota,$p_max_members)=split(/;/);
           if (not defined $p_name){$p_name=$project}
           if (not defined $p_long_name){$p_long_name=$p_name}
           if (not defined $p_teachers){$p_teachers=""}
           if (not defined $p_members){$p_members=""}
           if (not defined $p_member_groups){$p_member_groups=""}
           if (not defined $p_add_quota){$p_add_quota=""}
           if (not defined $p_max_members){$p_max_members=""}
           $count++;
           # Check of Parameters
           foreach $param (@_){
              ($attr,$value) = split(/=/,$param);
              printf "   %-18s : %-20s\n",$attr ,$value;
              if    ($attr eq "Name"){$p_name="$value"}
              elsif ($attr eq "LongName"){$p_long_name="$value"}
              elsif ($attr eq "Teachers"){$p_teachers="$value"}
              elsif ($attr eq "Members"){$p_members="$value"}
              elsif ($attr eq "MemberGroups"){$p_member_groups="$value"}
              elsif ($attr eq "AddQuota"){$p_add_quota="$value"}
              elsif ($attr eq "MaxMembers"){$p_max_members="$value"}
              elsif ($attr eq "File"){$file="$value"}
              elsif ($attr eq "Create"){$create=1}
              else {print "Attribute $attr unknown\n"}
	  }
          # change the Line
          $new_line=$p_name.";".$p_long_name.";".$p_teachers.";".
                    $p_members.";".$p_member_groups.";".$p_add_quota.";".
                    $p_max_members.";\n";
          print "OLD Line:   $old_line";
          print "NEW Line:   $new_line";
          print TMP "$new_line";         
        } else {
            print TMP "$old_line";
        }
    }
    # new file is in *.tmp
    if ($count==1){
        # one line found -> updating the project
	close(FILE);
	close(TMP);
       system("mv $file.tmp $file");  
    } elsif ($count==0 and $create==1){ 
        # 0 lines found -> creating the project
        print "Project $project is nonexisting -> CREATING\n";
        $p_name=$project;
        printf "   %-18s : %-20s\n","Name" ,$project;
        foreach $param (@_){
           ($attr,$value) = split(/=/,$param);
           printf "   %-18s : %-20s\n",$attr ,$value;
           if ($attr eq "LongName"){$p_long_name="$value"}
           elsif ($attr eq "Teachers"){$p_teachers="$value"}
           elsif ($attr eq "Members"){$p_members="$value"}
           elsif ($attr eq "MemberGroups"){$p_member_groups="$value"}
           elsif ($attr eq "AddQuota"){$p_add_quota="$value"}
           elsif ($attr eq "MaxMembers"){$p_max_members="$value"}
           elsif ($attr eq "File"){$file="$value"}
           elsif ($attr eq "Create"){$create=1}
           else {print "Attribute $attr unknown\n"}
        }
        # Enough Information to create the Project?
        if (not defined $p_long_name){$p_long_name=$project}
        if (not defined $p_teachers){$p_teachers="root"}
        if (not defined $p_members){$p_members=""}
        if (not defined $p_member_groups){$p_member_groups=""}
        if (not defined $p_add_quota){$p_add_quota=""}
        if (not defined $p_max_members){$p_max_members=""}
        $new_line=$p_name.";".$p_long_name.";".$p_teachers.";".
                  $p_members.";".$p_member_groups.";".$p_add_quota.";".
                  $p_max_members.";\n";
        print "OLD Line:   $old_line";
        print "NEW Line:   $new_line";
        print TMP "$new_line";         
	close(FILE);
        close(TMP);
        system("mv $file.tmp $file");  
    } elsif ($count==0){
        print "Project $project is nonexisting -> I do nothing\n";
        print "Use --create to create the project\n";
    }
    return $count;
}




=head2 FUNCTIONS

=head3 Searching

=over 4

=cut


=pod

=item I<linie()>

Creates a line.

=cut


# searches the user database and others for a user

# this must be implemented completely new
# because it searches in the lines of user.db


sub search_user {
  # database dependent
  my ($string) = @_;
  my $str="'\%$string\%'";

  my ($class,$gec_user,$login,$first_pass,$birth,$unid,
      $subclass,$status,$tol,$deact,$ex_admin,$acc_type,$quota)=();

  my ($loginname_passwd,$passwort,$uid_passwd,$gid_passwd,
     $quota_passwd,$name_passwd,$gcos_passwd,$home,$shell)=();

  my $group_string="";
  my @group_list=();
  my $pri_group_string="";
  my $grp_string="";
  my $home_ex="---";

  &Sophomorix::SophomorixBase::titel("I'm looking for $str in postgresql ...");
  my $dbh=&db_connect();

  my $sql="";

  # select the columns that i need
  my $sth= $dbh->prepare( "SELECT DISTINCT uid, firstname, surname, loginshell, 
                            birthday, adminclass, exitadminclass, 
                            unid, subclass, creationdate,tolerationdate, 
                            deactivationdate, sophomorixstatus,
                            gecos, homedirectory, firstpassword, quota,
                            sambaacctflags, sambahomepath, sambahomedrive,
                            sambalogonscript,sambaprofilepath 
                         FROM userdata
                         WHERE uid LIKE $str
                            OR firstname LIKE $str
                            OR surname LIKE $str
                            OR gecos LIKE $str
                            OR displayname LIKE $str" );
  $sth->execute();

  my $array_ref = $sth->fetchall_arrayref();

  foreach my $row (@$array_ref){
       my ($login,
           $firstname,
           $surname,
           $loginshell,
           $birthday_pg,
           $admin_class,
           $exit_admin_class,
           $unid,
           $subclass,
           $cre,
           $toleration_date_pg,
           $deactivation_date_pg,
           $status,
           $gecos,
           $home,
           $first_pass,
           $quota,
           $sambaacctflags, 
           $sambahomepath,
           $sambahomedrive,
           $sambalogonscript,
           $sambaprofilepath, 
           ) = @$row;

       my $birthday=&date_pg2perl($birthday_pg);
       my $tol=&date_pg2perl($toleration_date_pg);
       my $deact=&date_pg2perl($deactivation_date_pg);

       # Gruppen-Zugehoerigkeit
       $pri_group_string="";
       $grp_string="";
#       @group_list=&Sophomorix::SophomorixBase::get_group_list($login);
       @group_list=&Sophomorix::SophomorixPgLdap::pg_get_group_list($login);
       $pri_group_string=$group_list[0];

       if (defined $login){
	     print "($login exists in the system) \n";
       } else {
	     print "(ERROR: $login is not in the system) \n";
       }
       print "=======================================";
       print "=======================================\n";

       printf "  AdminClass       : %-47s %-11s\n",$admin_class,$login;
       printf "  PrimaryGroup     : %-47s %-11s\n",$pri_group_string,$login;

       foreach my $gr (@group_list){
	   $grp_string= $grp_string." ".$gr;
       }
       printf "  SecondaryGroups  :%-48s %-11s\n",$grp_string,$login;
       printf "  Gecos            : %-47s %-11s\n", $gecos,$login;

       if (-e $home){
          $home_ex=$home."  (existing)";
       } else {
          $home_ex=$home."  (ERROR: non-existing)";
       }
       if (defined $home){
          printf "  Home             : %-47s %-11s\n",$home_ex,$login;
       }

       if (defined $loginshell){
          printf "  loginShell       : %-47s %-11s\n",$loginshell,$login;
       }

       print "Sophomorix:\n";

       printf "  FirstPassword    : %-47s %-11s\n",$first_pass,$login;
       printf "  Birthday         : %-47s %-11s\n",$birthday,$login;

       if (defined $unid){
          printf "  Unid             : %-47s %-11s\n",$unid,$login;
       }

       if (defined $subclass){
	  printf "  SubClass         : %-47s %-11s\n",$subclass,$login;
       }

       if (defined $status){
	  printf "  Status           : %-47s %-11s\n",$status,$login;
       }

       if (defined $tol){
          printf "  CreationDate    : %-47s %-11s\n",$cre,$login;
       }

       if (defined $tol){
          printf "  TolerationDate   : %-47s %-11s\n",$tol,$login;
       }

       if (defined $deact){
          printf "  DeactivationDate : %-47s %-11s\n",$deact,$login;
       }

       if (defined $ex_admin){
	  printf "  ExitAdminClass   : %-47s %-11s\n",$ex_admin,$login;
       }

       if (defined $acc_type){
	  printf "  AccountType      : %-47s %-11s\n",$acc_type,$login;
       }

       if($Conf::use_quota eq "yes"){
          if (defined $quota){
	     printf "  Quota (MB)       : %-47s %-11s\n",$quota,$login;
          } else {
	     print  "  Quota (MB)       : --- \n";
          }
          if (-e "/usr/bin/quota"){
#	     print "  "; # indent output of following command
             # -l show only local quota, no nfs
             # -v show quota on unused filesystems          
             #system("quota -l -v $login");
             my $show=`quota -l -v $login`;
	     print "  "; # indent output of following command
             $show =~ s/\n  /\n/g; # remove indent partially
             print $show;
          }
       }

       print "Samba:\n";

       if (defined $sambaacctflags){
          printf "  sambaAcctFlags   : %-47s %-11s\n",$sambaacctflags,$login;
       }

       if (defined $sambahomepath){
          printf "  sambaHomePath    : %-47s %-11s\n",$sambahomepath,$login;
       }

       if (defined $sambahomedrive){
          printf "  sambaHomeDrive   : %-47s %-11s\n",$sambahomedrive,$login;
       }

       if (defined $sambalogonscript){
          printf "  sambaLogonScript : %-47s %-11s\n",$sambalogonscript,$login;
       }

       if (defined $sambaprofilepath){
          printf "  sambaProfilePath : %-47s %-11s\n",$sambaprofilepath,$login;
       }

       # samba, database independent
#       &Sophomorix::SophomorixBase::print_user_samba_data($login);
       # webmin, database independent
       &Sophomorix::SophomorixBase::print_user_webmin_data($login);

       if($Conf::log_level>=2){
          # history, database independent
          print "History of $login:\n";
          &Sophomorix::SophomorixBase::get_user_history($login);
          print "Mail forwarding of $login:\n";
          &Sophomorix::SophomorixBase::print_forward($login, $home);
       }
       print "\n";

       ($class,$gec_user,$login,$first_pass,$birth,$unid,
        $subclass,$status,$tol,$deact,$ex_admin,$acc_type,$quota)=(
        "","","","","","","","","","","","");
  }
}




=pod

=item  I<backup_sys_database()>

Makes a backup of the sophomorix user database

=cut

# this function can be left empty so far

sub backup_user_database {
#    my ($time, $string) = @_;
#    &do_falls_nicht_testen(
#      "cp ${DevelConf::protokoll_pfad}/user_db ${DevelConf::log_pfad}/${time}.user_db-${string}",
#      "chmod 600 ${DevelConf::log_pfad}/${time}.user_db-${string}"
#    );
}


=pod

=item  I<get_first-password(login)>

Returns the FirstPassword of the user login

=cut


# query the datadase for a users initial password 
sub get_first_password {
   my ($login) = @_;
   my $dbh=&db_connect();
   my $sql="";
   $sql="SELECT firstpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($first_pass)= $dbh->selectrow_array($sql);
   print "   First password: $first_pass\n";
   return $first_pass;
}




=pod

=item  I<check_sophomorix_user(login,uidnumber)>

Returns 1, if login is in the sophomorix database, and if it has
uidnumber uidnumber.

=cut


sub check_sophomorix_user {
  my ($login,$id) = @_;
  my $result=0;
  my $dbh=&db_connect();
  my $sql="";
  $sql="SELECT id,uidnumber FROM userdata WHERE uid='$login'";
  if($Conf::log_level>=3){
     print "\nSQL: $sql\n";
  }
  my ($uid,$uidnumber)= $dbh->selectrow_array($sql);
  if (defined $id and $uidnumber!=$id){
      print "$login ($uidnumber) exists but uidnumber is not $id\n";
      $result=0;
  } elsif (defined $uid) {
      $result=1;
  } else {
      $result=0;
  }
  &db_disconnect($dbh);
  return $result;
}







sub check_sophomorix_user_oldstuff {
  my ($username) = @_;
  my $result=0;
  open(PASSPROT, "$DevelConf::dyn_config_pfad/user_db");
  while(<PASSPROT>) {
      chomp(); # Returnzeichen abschneiden
      s/\s//g; # Spezialzeichen raus
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      my ($gruppe, $nax, $login, $pass) = split(/;/);
      if ($username eq $login) {
        $result=1;
      }
  }
  close(PASSPROT);
  return $result;
}




sub show_project_list {
   print "The following projects exist already:\n\n";
   printf "%-16s %-16s %-9s %-40s\n","Name:", "Teachers", "AddQuota", "LongName:";
   print "=======================================",
         "=======================================\n";
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid,teachers,addquota,longname 
                             FROM projectdata" );
      $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();

    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
	#chomp($gid);
        my $teachers=${$array_ref}[$i][1];
        my $addquota=${$array_ref}[$i][2];
        my $longname=${$array_ref}[$i][3];
        if (not defined $gid){
	    $gid="";
        }
        if (not defined $teachers){
	    $teachers="";
        }
        if (not defined $addquota){
	    $addquota="";
        }
        if (not defined $longname){
	    $longname="";
        }
#	print "---$gid---\n";
#	print "---$longname---\n";
#	print "---$addquota---\n";
#	print "---$teachers---\n";

        printf "%-16s %-16s %-9s %-40s\n",$gid, $teachers,
                                          $addquota, $longname;
        $i++;
    }   
}



sub show_project_list_oldstuff {
   open(PROJECT,"<${DevelConf::dyn_config_pfad}/projects_db") || die "Fehler: $!";
   print "The following projects exist already:\n\n";
   printf "%-16s %-16s %-9s %-40s\n","Name:", "Teachers", "AddQuota", "LongName:";

   print "=======================================",
         "=======================================\n";
   while(<PROJECT>){
       chomp();
       my @line=split(/;/);
       if (not defined $line[1]){$line[1]="---"}
       if (not defined $line[2]){$line[2]="---"}
       if (not defined $line[5]){$line[5]="---"}
       printf "%-16s %-16s %-9s %-40s\n",$line[0], $line[2], $line[5], $line[1];
   }
   close(PROJECT);
   print "\n";
}



# (deprecated)

sub show_class_list {
   open(CLASS,"<${DevelConf::dyn_config_pfad}/class_db") || die "Fehler: $!";
   print "The following AdminClasses exist:\n\n";
   printf "%-14s %-14s %-5s %-10s %-12s %-14s \n",
          "AdminClass:", "Dept.:", "Typ" , "Mail:", "Quota", "AdminClass";

   print "=======================================",
         "=======================================\n";
   while(<CLASS>){
       chomp();
       my @line=split(/;/);
       if (not defined $line[1]){$line[1]="---"}
       if (not defined $line[2]){$line[2]="---"}
       if (not defined $line[3]){$line[3]="---"}
       if (not defined $line[4]){$line[4]="---"}
       printf "%-14s %-14s %-5s %-10s %-12s %-14s\n",
              $line[0], $line[1],$line[2], $line[3], $line[4], $line[0];
   }
   close(CLASS);
   print "\n";
}


sub smb_user_sid {
    my ($uidnumber,$sid) = @_;
    my $user_sid = 2*$uidnumber+1000;
    $user_sid = "$sid"."-"."$user_sid"; 
    return $user_sid;
}


sub smb_group_sid {
    # when adding a user
    my ($gidnumber,$sid) = @_;
    my $group_sid=2*$gidnumber+1001;
    $group_sid="$sid"."-"."$group_sid";
    return $group_sid;
}


sub get_smb_sid {
    $sid_string=`net getlocalsid`;
    chomp($sid_string);
    my ($rubbish,$sid) = split(/: /,$sid_string);
    return $sid;
}




# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
