#!/usr/bin/perl -w
# Dieses Modul (SophomorixFiles) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

package Sophomorix::SophomorixFiles;
require Exporter;
@ISA =qw(Exporter);
@EXPORT = qw(show_modulename
             move_user_from_to
	     create_user_db_entry
	     delete_user_db_entry
	     update_user_db_entry
             provide_class
             move_user_db_entry
             get_sys_users
);

use Sophomorix::SophomorixBase qw ( titel );

sub show_modulename {
    &titel("DB-Backend-Module: SophomorixFiles.pm");
}

sub move_user_from_to {
    # Parameter 1: user_login
    # Parameter 2: linux_group in which the user is
    # Parameter 3: new linux_group 
    my ($user, $old_linux_group, $new_linux_group) = @_;
    &add_user_to_group($user, $new_linux_group);
    &remove_user_from_group($user, $old_linux_group);
}



#sub real_2_linux_class {
#    # converts a real groupname to a
#    # linux groupname
#    my ($real) = @_;
#    my $linux = "k"."$real";
#    return $linux;
#}



#sub linux_2_real_classw {
#    # converts a linux groupname to a
#    # real groupname
#    my ($linux) = @_;
#    my $first_letter=substr($linux,0,1);
#    if ($first_letter ne "k"){
#      print "\nError converting linux_group $linux to real_group\n"; 
#      print "first letter must be a 'k'\n\n";
#      exit;
#    }
#    my $real = substr($linux,1,200);
#    #print "Erster buchstabe : $first_letter \n";
#    #print "Realer Name: $real \n";
#    return $real;
#}



sub create_user_db_entry {
    my ($nachname,
       $vorname,
       $gebdat,
       $class,
       $login,
       $pass,
       $sh,
       $quota) = @_;

    my $gec = "$vorname"." "."$nachname";
    my $home ="";
    if ($class eq "lehrer"){
       $home = "/home/lehrer/$login";
    } else {
       $home = "/home/schueler/$class/$login";
    }
    &provide_class($class);
    &do_falls_nicht_testen(
       "useradd -c '$gec' -d $home -m -g $class -p $pass -s $sh $login"
    );
}


sub delete_user_db_entry {
    ($login)=@_;
    &do_falls_nicht_testen(
       # aus smbpasswd entfernen
       "/usr/bin/smbpasswd  -x $login",
       # Aus Benutzerdatenbank entfernen (-r: Home löschen)
       "userdel  -r $login",
    );
}



sub provide_class {
    my ($class) = @_;
    my $klassen_homes="/home/schueler/$class";
    my $klassen_tausch="/home/tausch/klassen/$class";
    my $klassen_aufgaben="/home/aufgaben/$class";
    &setup_verzeichnis("/home/schueler/\$klassen",
                    "$klassen_homes");
    &setup_verzeichnis("/home/tausch/klassen/\$klassen",
                    "$klassen_tausch");
    &setup_verzeichnis("/home/aufgaben/\$klassen",
                    "$klassen_aufgaben");
    &do_falls_nicht_testen(
       "groupadd $class",
    );
}


sub move_user_db_entry {
   #user in db versetzen
    print "Moving user in files \n";
    my $pro_login="";
    my ($login,$new_class,$old_class) = @_;
      open(PROTOKOLLNEW,">$DevelConf::protokoll_datei.new");
      open(PROTOKOLL,"<$DevelConf::protokoll_datei");
         while (<PROTOKOLL>) {
	     ($a,$a,$pro_login)=split(/;/);
             if ($pro_login eq $login){
		 s/$old_class/$new_class/;
             }
	        print PROTOKOLLNEW "$_";
   	 }
      close(PROTOKOLL);
    system ("mv $DevelConf::protokoll_datei.new $DevelConf::protokoll_datei");
} 



#sub set_toleration_date {
#
#}

###########################################################################
# CHECKED, NEW
###########################################################################


sub get_sys_users {
   my $number=1;
   my $login="";
   my $admin_class="";
#   my $linux_class="";
   my $identifier="";
   my $unid="";
   my $subclass="";
   my $status="";
   my $toleration_date="";
   my $deactivation_date="";
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

# user.protokoll   einlesen
open(USERIMSYSTEM, 
     ">${DevelConf::ergebnis_pfad}/${DevelConf::schueler_oder_user}.imsystem")
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
    $deactivation_date
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
   ($vorname_passwd,$nachname_passwd)=split(/ /,$gcos_passwd);
   # Zusammenhängen zu identifier
   $identifier_passwd=join("",
                             ($nachname_passwd,
                              ";",
                              $vorname_passwd,
                              ";",
                              $geburtsdatum_protokoll));

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
          printf "%-16s%-50s\n",
                 "Aus passwd:","$identifier_passwd\n\n";
          printf "%-16s%-50s\n",
                 "Aus protokoll:","$identifier\n\n";
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

   if($Conf::log_level>=3){
      print "\n";
      print "Line $number(user.protokoll):  ",$_,"\n";
      print "User $number  Attributes (MUST): \n";
      print "  Login       :   $login \n"; 
#      print "  Erstpass    :   $password_pro \n"; 
#      print "  LinuxClass  :   $linux_class \n";
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

          print "\n";
   }# end loglevel
 
   # add the user to the hashes
   $identifier_adminclass{$identifier} = "$admin_class";
   $identifier_login{$identifier} = "$login";
   $identifier_status{$identifier} = "$status";

   # TolerationDate is optional
   if ($toleration_date ne "") {        
      $identifier_toleration_date{$identifier} = "$toleration_date";
   }

   # DeactivationDate is optional
   if ($deactivation_date ne "") {        
      $identifier_deactivation_date{$identifier} = "$deactivation_date";
   }

   # subclass is optional
   if ($subclass ne "") {        
      $identifier_subclass{$identifier} = "$subclass";
   }

   # unid is optional
   if ($unid ne "") {        
      $unid_identifier{$unid} = "$identifier";
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
         );
}

=head1 update_user_db_entry

Parameter 1: Loginname of user to be updated

Parameter 2: List with Attribute=Value

=cut

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
    my $file="${DevelConf::protokoll_pfad}/user.protokoll";

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
            $subclass,$status,$toleration_date,$deactivation_date)=split(/;/);
            # filling undefined attr with empty string
	    if (not defined $unid){$unid=""}
	    if (not defined $subclass){$subclass=""}
	    if (not defined $status){$status=""}
	    if (not defined $toleration_date){$toleration_date=""}
	    if (not defined $deactivation_date){$deactivation_date=""}
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
              else {print "Attribute $attr unknown\n"}
	  }
          # change the Line
          $new_line=$admin_class.";".$name." ".$lastname.";".$login.";".
          $first_pass.";".$birthday.";".$unid.";".$subclass.";".
          $status.";".$toleration_date.";".$deactivation_date.";"."\n";
          #print "OLD Line:   $old_line";
          #print "NEW Line:   $new_line";
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


# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
