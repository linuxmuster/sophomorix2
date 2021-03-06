#!/usr/bin/perl -w
# This perl module is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@gmx.de


package Sophomorix::SophomorixFiles;
require Exporter;
@ISA =qw(Exporter);
@EXPORT = qw(show_modulename
             check_connections
	     create_user_db_entry
             create_class_db_entry
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
             show_class_list
);
# deprecated:             move_user_db_entry
#                         move_user_from_to


# ??????????
# here i dont need to say Sophomorix::SophomorixBase::titel
# as in SophomorixSYSFiles. Whats wrong?
use Sophomorix::SophomorixBase qw ( titel
                                    do_falls_nicht_testen
                                    provide_class_files
                                    get_group_list
                                    print_user_samba_data
                                    get_user_history
                                    print_forward
                                  );


# ===========================================================================
# Loading the sys-db-Module, list of functions
# ===========================================================================
# list of functions to load if sys_db is 'files'
use if ${DevelConf::sys_db} eq 'files' , 
    'Sophomorix::SophomorixSYSFiles' => qw( add_class_to_sys
                                            get_user_auth_data
                                          );


=head1 Documentation of SophomorixFiles.pm

=head2 FUNCTIONS


=cut


sub check_connections {
   # nothing to do
}


sub show_modulename {
#    if($Conf::log_level>=2){
       &titel("DB-Backend-Module:   SophomorixFiles.pm");
#   }
}




# adds a user to the user database
sub create_user_db_entry {
    my ($nachname,
       $vorname,
       $gebdat,
       $class,
       $login,
       $pass,
       $sh,
       $quota,
       $unid) = @_;

    if (not defined $unid){
	$unid="";
    }

    my $gec = "$vorname"." "."$nachname";
    if ($DevelConf::testen==0) {
       open(PROTOKOLL,">>$DevelConf::protokoll_datei");
       # zeile anhängen
       print PROTOKOLL "$class;$gec;$login;$pass;$gebdat;$unid;;;;;;;$quota;\n";
       # Datei Schließen, damit Schreiben erzwingen (Falls Programmabsturz)
       close(PROTOKOLL);
  } else {
       print "Test:   modifying $DevelConf::protokoll_datei \n";
  }

}




# adds a class to the user database
sub create_class_db_entry {
    my ($class_to_add) = @_;
    my %classes=();
    my ($class,$dept,$type,$mail,$quota) = ("","","","","");
    # which classes exist
    open(CLASS,"<${DevelConf::protokoll_pfad}/class_db");
    while (<CLASS>) {
       ($class,$dept,$type,$mail,$quota)=split(/;/);
       $classes{$class}="some info";
    }
    close(CLASS);
    
    # append if nonexistent
    if (not exists $classes{$class_to_add}){
    open(CLASS,">>${DevelConf::protokoll_pfad}/class_db");
    print CLASS "$class_to_add".";;;;quota;\n";
    close(CLASS);
    }
}




=pod

=item I<set_sophomorix_passwd(login,string)>

Setzt das Passwort string in linux, samba, ...

=cut


sub set_sophomorix_passwd {
    my ($login,$pass) = @_;
    if ($DevelConf::testen==0) {
       # Passwort verschlüsseln
       open(PASSWD,"| /usr/sbin/chpasswd");
          print PASSWD "$login:$pass\n";     
       close(PASSWD);
       # Passwort in smbpasswd setzen
       open(SMBPASSWD,"| /usr/bin/smbpasswd -s -a $login");
          print SMBPASSWD "$pass\n$pass\n"; 
       close(SMBPASSWD);
  } else {
     print "Test: Setting password \n";
  }
}






###########################################################################
# CHECKED, NEW
###########################################################################


# reads the user database into perl hashes.
# the scripts all work with the perl hashes (instead of the database itself)
sub get_sys_users {
   my $number=1;
   my $login="";
   my $admin_class="";
   my $identifier="";
   my $unid="";
   my $subclass="";
   my $status="";
   my $toleration_date="";
   my $deactivation_date="";
   my $exit_admin_class="";
   my $account_type="",
   my $name_pro="";
   my $vorname_pro="";
   my $nachname_pro="";
   my $password_pro="";
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

# user_db   einlesen
open(USERIMSYSTEM, 
     ">${DevelConf::ergebnis_pfad}/sophomorix.system")
     || die "Fehler: $!";
open(USERPROTOKOLL,
     "<${DevelConf::protokoll_datei}") 
     || die "Fehler: $!";

system ("chmod 600 $DevelConf::protokoll_datei");

 while(<USERPROTOKOLL>){
    chomp($_); # Newline abschneiden

    # Protokolldatei bearbeiten
   ($admin_class, 
    $name_pro,
    $login,
    $password_pro,
    $geburtsdatum_protokoll,
    $unid,
    $subclass,
    $status,
    $toleration_date,
    $deactivation_date,
    $exit_admin_class,
    $account_type
   )=split(/;/);

   # Name aufsplitten
   ($vorname_pro,$nachname_pro)=split(/ /,$name_pro);
   # Zusammenhängen zu identifier
   $identifier=join("",
         ($nachname_pro,";",
          $vorname_pro,";",
          $geburtsdatum_protokoll));

   # Abfragen der /etc/passwd
   ($loginname_passwd,
    $passwort,
    $uid_passwd,
    $gid_passwd,
    $quota_passwd,
    $name_passwd,
    $gcos_passwd, # Hier steht "Vorname Nachname"
   )=getpwnam("$login");
   # GCOS-Feld aufsplitten
   if (defined $gcos_passwd){
       ($vorname_passwd,$nachname_passwd)=split(/ /,$gcos_passwd);
   # Zusammenhängen zu identifier
   $identifier_passwd=join("",
                             ($nachname_passwd,
                              ";",
                              $vorname_passwd,
                              ";",
                              $geburtsdatum_protokoll));
   } else {
       $identifier_passwd="not found";
   }
   # In Hash schreiben: mit Klasse als Wert (um Versetzen herauszufinden)
   $schueler_im_system_hash{$identifier}="$admin_class";
   # In Hash schreiben: mit loginnamen als Wert (um Löschen herauszufinden)
   $schueler_im_system_loginname{$identifier}="$login";
   # In Hash schreiben: mit Zeile als Wert (beim Löschen zu entfernen)
   $schueler_im_system_protokoll_linie{$identifier}="$_";
  
   if ($DevelConf::kompatibel eq "ja"){
      # Nehme den identifier aus schueler.protokoll, da dort OK 
      # (van,von-Bug in versetzen.pl)
      print USERIMSYSTEM "$identifier\n";
   } else {
      # Folgender Teil ist besser, da er auf identische Daten
      # aus /etc/passwd und schueler.protokoll wert legt 
      if ($identifier_passwd eq $identifier){
          print USERIMSYSTEM "$identifier_passwd\n";
       } else {
          print "\n\n\n\n PROGRAMMABBRUCH: ",
                "$DevelConf::protokoll_datei inkonsistent:\n";
          print "Aus passwd:     $identifier_passwd\n";
          print "Aus protokoll:  $identifier\n";
          print  "Beheben Sie diesen Fehler manuell durch editieren von \n";
          print  "   $DevelConf::protokoll_datei\n";
          exit;
       }
   }

   # exclude the admin-account
   # better: admin should also have the attributes as the other users
   if ($login eq "admin"){
       next;
   }       


   if (not defined $unid){$unid=""}
   if (not defined $subclass){$subclass=""}
   if (not defined $status){$status=""}
   if (not defined $toleration_date){$toleration_date=""}
   if (not defined $deactivation_date){$deactivation_date=""}
   if (not defined $exit_admin_class){$exit_admin_class=""}
   if (not defined $account_type){$account_type=""}

   if($Conf::log_level>=3){
      print "\n";
      print "Line $number(user_db):  ",$_,"\n";
      print "User $number  Attributes (MUST): \n";
      print "  Login       :   $login \n"; 
      print "  AdminClass  :   $admin_class \n";
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
 close(USERPROTOKOLL);
 close(USERIMSYSTEM);

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





# returns users in the system that are not in schueler.txt/lehrer.txt
# i.e. the users for  teach-in

# returns a list of users with status D,T,S,A

sub get_teach_in_sys_users{
   open(TOLERATION,"<${DevelConf::dyn_config_pfad}/user_db");
   while(<TOLERATION>){
     my @line=split(/;/);
     if(defined $line[7] and ($line[7] eq "D" or 
                              $line[7] eq "T" or
                              $line[7] eq "S" or
                              $line[7] eq "A")){
       #print "Element: $line[7] \n";
       if ($line[7]){
         my $gecos=$line[1];
         my ($first,$last)=split(/ /,$gecos);
         my $identifier=$last.";".$first.";".$line[4];
         #print $identifier."\n";
         push @toleration, $identifier;
       }	    
     }
   }
   close(TOLERATION);
   return @toleration;
}





# returns a list of the following lines from all users:
# Syntax:
#   class;firstname lastname;loginname;FirstPassword;birthday;  

sub get_print_data {
    my @lines=();
    open(USERPROTOKOLL,"$DevelConf::protokoll_datei") 
        || die "Fehler:  $DevelConf::protokoll_datei nicht gefunden!  $!";
    while(<USERPROTOKOLL>){
	push @lines, $_;
    }
    return @lines;
}


=head1 update_user_db_entry

Parameter 1: Loginname of user to be updated

Parameter 2: List with Attribute=Value

=cut

# this function changes the fields of the user login

sub update_user_db_entry {
    my $param="";
    my $login_file="";
    my $old_line="";
    my $new_line="";
    my $count=0;

    my $admin_class="";
    my $lastname="";
    my $name="";
    my $login=shift;
    my $first_pass="";
    my $birthday="";
    my $unid="";
    my $subclass="";
    my $status="";
    my $toleration_date="",
    my $deactivation_date="";
    my $exit_admin_class="";
    my $account_type="";
    my $quota="";
    my $file="${DevelConf::protokoll_pfad}/user_db";

    # Which file?
    foreach $param (@_){
       ($attr,$value) = split(/=/,$param);
       if ($attr eq "File"){$file="$value"}
    } 

    open(TMP, ">$file.tmp");
    open(FILE, "<$file");
    while(<FILE>){
        $old_line=$_;
	($a,$a,$login_file)=split(/;/);
        if ($login eq $login_file){
           # found the line
	    chomp();
           ($admin_class,$gecos,$login_file,$first_pass,$birthday,$unid,
            $subclass,$status,$toleration_date,$deactivation_date,
            $exit_admin_class,$account_type,$quota)=split(/;/);
            # filling undefined attr with empty string
	    if (not defined $unid){$unid=""}
	    if (not defined $subclass){$subclass=""}
	    if (not defined $status){$status=""}
	    if (not defined $toleration_date){$toleration_date=""}
	    if (not defined $deactivation_date){$deactivation_date=""}
	    if (not defined $exit_admin_class){$exit_admin_class=""}
	    if (not defined $account_type){$account_type=""}
	    if (not defined $quota){$quota=""}
	   ($name,$lastname)=split(/ /,$gecos);
	    $count++;
           # Check of Parameters
           foreach $param (@_){
              ($attr,$value) = split(/=/,$param);
 #             printf "   %-18s : %-20s\n",$attr ,$value;
              if    ($attr eq "AdminClass"){$admin_class="$value"}
              elsif ($attr eq "Name"){$name="$value"}
              elsif ($attr eq "LastName"){$lastname="$value"}
              elsif ($attr eq "FirstPass"){$first_pass="$value"}
              elsif ($attr eq "Birthday"){$birthday="$value"}
              elsif ($attr eq "Unid"){$unid="$value"}
              elsif ($attr eq "SubClass"){$subclass="$value"}
              elsif ($attr eq "Status"){$status="$value"}
              elsif ($attr eq "TolerationDate"){$toleration_date="$value"}
              elsif ($attr eq "DeactivationDate"){$deactivation_date="$value"}
              elsif ($attr eq "File"){$file="$value"}
              elsif ($attr eq "ExitAdminClass"){$exit_admin_class="$value"}
              elsif ($attr eq "AccountType"){$account_type="$value"}
              elsif ($attr eq "Quota"){$quota="$value"}
              else {print "Attribute $attr unknown\n"}
	  }
          # change the Line
          $new_line=$admin_class.";".$name." ".$lastname.";".$login.";".
          $first_pass.";".$birthday.";".$unid.";".$subclass.";".
          $status.";".$toleration_date.";".$deactivation_date.";".
          $exit_admin_class.";".$account_type.";".$quota.";"."\n";
          print TMP "$new_line";         
        } else {
            print TMP "$old_line";
        }
    }

    # new file is in *.tmp
    if ($count==1){
	close(TMP);
	close(FILE);
       system("mv $file.tmp $file");  
    }

    #print "$count OLD line found \n\n";
    return $count;
}



# this function removes a user entry in the database 
sub remove_user_db_entry {
    my ($login) = @_;
    my $login_file="";
    my $file="${DevelConf::protokoll_pfad}/user_db";
    open(TMP, ">$file.tmp");
    open(FILE, "<$file");
    while(<FILE>){
        ($a,$a,$login_file)=split(/;/);
        if ($login eq $login_file){
           # found the line, dont use it
        } else {
	   print TMP $_;
        }
    }
    close(TMP);
    close(FILE);
    system("mv $file.tmp $file");  
}





# ===========================================================================
# User DE-aktivieren
# ===========================================================================

# deactivate a users login, ...

sub user_deaktivieren {
   my ($loginname) = @_;
   # samba
   my $samba_string="smbpasswd -d $loginname >/dev/null";
   system("$samba_string");
   # linux
   my $linux_string="usermod -L $loginname >/dev/null";
   system("$linux_string");
   if($Conf::log_level>=2){
      print "User $loginname wird deaktiviert:\n";
      print "  Samba:  $samba_string\n";
      print "  Linux:  $linux_string\n";
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
   my ($loginname) = @_;
   # samba
   my $samba_string="smbpasswd -e $loginname >/dev/null";
   system("$samba_string");
   # linux
   my $linux_string="usermod -U $loginname >/dev/null";
   system("$linux_string");
   if($Conf::log_level>=2){
      print "User $loginname wird reaktiviert:\n";
      print "  Samba:  $samba_string\n";
      print "  Linux:  $linux_string\n";
   }
   system("smbpasswd -e $loginname >/dev/null");
   # linux-login
   # ToDo
   # mailabruf
   # ToDo
   # public:html:
      # NICHT entsperren
   # Ende des Eintrags
   if($Conf::log_level>=2){
      print "\n";
   }
}





# create a project (can be implemented later)

sub create_project_db {
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
  my ($class,$gec_user,$login,$first_pass,$birth,$unid,
      $subclass,$status,$tol,$deact,$ex_admin,$acc_type,$quota)=();

  my ($loginname_passwd,$passwort,$uid_passwd,$gid_passwd,
     $quota_passwd,$name_passwd,$gcos_passwd,$home,$shell)=();

  my $group_string="";
  my @group_list=();
  my $pri_group_string="";
  my $grp_string="";
  my $home_ex="---";

  &Sophomorix::SophomorixBase::titel("I'm looking for $string in $DevelConf::protokoll_datei ...");
  open(PROTOKOLL,"<$DevelConf::protokoll_datei");
  while (<PROTOKOLL>){
    if (/$string/){
       chomp();

       ($class,$gec_user,$login,$first_pass,$birth,
       $unid,$subclass,$status,$tol,$deact,$ex_admin,$acc_type,$quota)=split(/;/);

       ($loginname_passwd,$passwort,$uid_passwd,$gid_passwd,$quota_passwd,
       $name_passwd,$gcos_passwd,$home,$shell)=&Sophomorix::SophomorixBase::get_user_auth_data($login);

       # Gruppen-Zugehoerigkeit
       $pri_group_string="";
       $grp_string="";
       @group_list=&Sophomorix::SophomorixBase::get_group_list($login);
       $pri_group_string=$group_list[0];

	  print "User                :  $login  ";
       if (defined $loginname_passwd){
	     print "($loginname_passwd exists in the system) \n";
       } else {
	     print "(ERROR: $login is not in the system) \n";
       }
       print "=======================================";
       print "=======================================\n";

       printf "  AdminClass       : %-47s %-11s\n",$class,$login;
       printf "  PrimaryGroup     : %-47s %-11s\n",$pri_group_string,$login;
       foreach my $gr (@group_list){
	   $grp_string= $grp_string." ".$gr;
	  #print $gr," ";
       }
       printf "  SecondaryGroups  :%-48s %-11s\n",$grp_string,$login;
       printf "  Gecos            : %-47s %-11s\n", $gec_user,$login;
  
       if (defined $loginname_passwd){
          printf "  SystemGecos      : %-47s %-11s\n",$gcos_passwd, $login;
       }

       if (-e $home){
          $home_ex=$home."  (existing)";
	  #print "(existing) \n";
       } else {
          #print "(ERROR: non-existing!) \n";
          $home_ex=$home."  (ERROR: non-existing)";
       }
       if (defined $home){
          printf "  Home             : %-47s %-11s\n",$home_ex,$login;
       }

       if (defined $shell){
          printf "  LoginShell       : %-47s %-11s\n",$shell,$login;
       }

       printf "  FirstPassword    : %-47s %-11s\n",$first_pass,$login;
       printf "  Birthday         : %-47s %-11s\n",$birth,$login;

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
#             system("quota -l -v $login");
             my $show=`quota -l -v $login`;
	     print "  "; # indent output of following command
             $show =~ s/\n  /\n/g; # remove indent partially
             print $show;
          }
       }
       # samba, database independent
       &Sophomorix::SophomorixBase::print_user_samba_data($login);
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
  close(PROTOKOLL);
}





=pod

=item  I<backup_sys_database()>

Makes a backup of the sophomorix user database

=cut

# this function can be left empty so far

sub backup_user_database {
    my ($time, $string) = @_;
    &do_falls_nicht_testen(
      "cp ${DevelConf::protokoll_pfad}/user_db ${DevelConf::log_pfad}/${time}.user_db-${string}",
      "chmod 600 ${DevelConf::log_pfad}/${time}.user_db-${string}"
    );
}


=pod

=item  I<get_first-password(login)>

Returns the FirstPassword of the user login

=cut


# query the datadase for a users initial password 
# (can be implemented later)

sub get_first_password {
  my ($username) = @_;
  open(PASSPROT, "$DevelConf::dyn_config_pfad/user_db");
  while(<PASSPROT>) {
      chomp(); # Returnzeichen abschneiden
      s/\s//g; # Spezialzeichen raus
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      my ($gruppe, $nax, $login, $pass) = split(/;/);
      if ($username eq $login) {
        return $pass;
      }
  }
  close(PASSPROT);
}




=pod

=item  I<check_sophomorix_user(login)>

Returns 1, if  login is in the sophomorix database.

=cut

# (can be implemented later)

sub check_sophomorix_user {
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



# (can be implemented later)

sub show_project_list {
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



# (can be implemented later)

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








# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
