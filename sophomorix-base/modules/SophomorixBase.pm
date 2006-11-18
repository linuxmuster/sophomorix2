#!/usr/bin/perl -w
# $Id$
# Dieses Modul (SophomorixBase.pm) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

# aufspalten in:  
#    SophomorixBase
#    SophomorixQuota
#    SophomorixSamba
#    SophomorixAPI

package Sophomorix::SophomorixBase;
require Exporter;
use Time::Local;
use Time::localtime;
use Quota;

@ISA = qw(Exporter);

@EXPORT_OK = qw( check_datei_touch );
@EXPORT = qw( linie 
              titel
              alpha_warning
              print_list 
              print_list_column 
              print_hash
              get_alle_verzeichnis_rechte
              get_v_rechte
              setup_verzeichnis
              make_some_files_root_only
              remove_line_from_file
              get_old_info 
              save_tausch_klasse
              extra_kurs_schueler
              lehrer_ordnen
              zeit_stempel
              recode_to_ascii
              do_falls_nicht_testen
              check_options
              check_datei_exit
              check_config_template
              check_datei_touch
              check_verzeichnis_mkdir
              get_user_history
              get_group_list
              print_forward
              get_passwd_charlist
              get_random_password
              get_plain_password
              reset_user
              create_share_link
              create_share_directory
              remove_share_link
              remove_share_directory
              zeit
              pg_timestamp
              append_teach_in_log
              log_script_start
              log_script_end
              log_script_exit
              unlock_sophomorix
              lock_sophomorix
              archive_log_entry
              backup_amk_file
              get_mail_alias_from
              imap_connect
              imap_disconnect
              imap_show_mailbox_info
              imap_create_mailbox
              imap_kill_mailbox
              imap_fetch_mailquota
              imap_set_mailquota
              get_quotastring
              setze_quota
              addup_quota
              quota_addition
              get_standard_quota
              get_lehrer_quota
              get_quota_fs_liste
              get_quota_fs_num
              check_quotastring
              sophomorix_passwd
              check_internet_status
              austeilen_manager
              share_access
              handout
              handoutcopy
              collect
              provide_class_files
              provide_subclass_files
              provide_project_files
              remove_project_files
              provide_user_files
              fetchhtaccess_from_user
              user_public_upload
              user_public_noupload
              user_private_upload
              user_private_noupload
              fetchhtaccess_from_group
              group_public_upload
              group_public_noupload
              group_private_upload
              group_private_noupload
              get_debconf_value
              );




=head1 Documentation of SophomorixBase.pm


B<sophomorix> is a user administration tool for a school server. It
lets you administrate a huge amount of users by exporting all pupils of
a school into a file and reading them into a linux system.

B<Sophomorix> will in the future use different backends (files, ldap,
SQL-Databases, ...) to store its data. If you want to access this data
you could talk to the backend directly, but this would mean, that you
would have to update your scripts when the data organisation in the
backend changes.

A better way is to use only the functions of B<SophomorixBase>. So if
the data organisation changes you only have to get a current version
of B<SophomorixBase> and youre off.


=head2 FUNCTIONS

=head3 Formatting

=over 4

=cut
#    my $develconf="/usr/share/sophomorix/devel/sophomorix-devel.conf";
#if (not -e $develconf){
#    print "ERROR: $develconf not found!\n";
#    exit;
#}

# Einlesen der Konfigurationsdatei für Entwickler
#{ package DevelConf ; do "/etc/sophomorix/devel/user/sophomorix-devel.conf"}
#{ package DevelConf ; do "$develconf"}

# Einlesen der Konfigurationsdatei
#{ package Conf ; do "${DevelConf::config_pfad}/sophomorix.conf"}
# Die in sophomorix.conf als global (ohne my) deklarierten Variablen
# können nun mit $Conf::Variablenname angesprochen werden


################################################################################
# FORMATTING
################################################################################
=pod

=item I<linie()>

Creates a line.

=cut
sub linie {
   print "========================================",
         "========================================\n";
}


=pod

=item I<titel(text)>

Creates a framed titel with the text I<text>. The frame is thinner,
when --verbose is not used.

=cut
sub titel {
   my ($a) = @_;

   if($Conf::log_level>=2){
   print  "\n#########################################", 
                            "#######################################\n";
   printf "%-3s %-67s %-2s"," #","$a","#";
   print  "\n########################################",
                            "########################################\n";
   } else {
         printf "%-3s %-67s %-3s\n", "#####", "$a", "#####";
   }
}

sub alpha_warning {
    print "\n WARNING: you are trying to use a feature of sophomorix";
    print "\n          that is considered DANGEROUS!";
    print "\n          It is not recommended to use it on a production server!\n";
    print "\n Type Ctrl-c to exit or 'ok' + <Return> to continue!\n\n";
    while(){# Endlosschleife für die Eingabe
         $user_antwort= <STDIN>; # Lesen von Tastatur
         chomp($user_antwort); # Newline abschneiden
         if ($user_antwort eq "ok"){
            print "... continuing in 1 s\n\n";
            sleep 1;
             last; 
         } else {
	     exit;
         }
    }
}

=pod

=item I<print_list(name,@liste)>

prints every element of a list on a single line, if loglevel is 3
(option -vv) and shows the header name.

=cut
sub print_list {
   my $name=shift;
   my @list= @_;
   my $number=$#list+1;
   if($Conf::log_level>=3){
       print "\nBegin: $name ($number)\n";
       foreach my $element (@list){
	   print "   $element\n";
       }
       print "End: $name ($number)\n\n";

   }
}

=pod

=item I<print_list(name,@liste)>

prints every element of a list on a single line, if loglevel is 3
(option -vv) and shows the header name.

=cut
sub print_hash {
   my ($hashref,$titel,$key,$value,$key_length,$value_length)= @_;
   
   printf "+---------------------------+---------------------------+\n",$titel;
   if ($titel ne ""){
       printf "+ %-53s +\n",$titel;
       printf "+---------------------------+---------------------------+\n",$titel;
   }
   %hash = %$hashref;
   printf "| %-25s | %-25s |\n",$key,$value;
   printf "+ %-25s + %-25s +\n","-------------------------",
          "-------------------------";
   while( my ($k, $v) = each(%hash)) {
     printf "| %-25s | %-25s |\n",$k,$v;
   }
   printf "+ %-25s + %-25s +\n","-------------------------",
          "-------------------------";
}

=pod

=item I<print_list_column(num,name,@liste)>

prints the elements of a list in num=2,4 or 6 columns, and shows the header name.

=cut


sub print_list_column {
   # number of rows
   my $number=shift();
   # the title
   my $title=shift();
   # the list to print
   my @list=@_;

   my %allowed = qw ( 2 2 4 4 6 6 );
   if (not exists $allowed{$number}){
      # do nothing
       print "print_list_column: Cant display $number columns\n";
   } else {
      my $index_number=$number-1;
      my @linelist=();
      my $all=$#list+1;
      my $left=$all % $number;
      my $to_add=$number-$left;
      my $i;
      #print "$all divided by $number is $left left, add $to_add\n";

      # add the missing elements
      if ($all!=$number){
         for ($i = 1; $i <= $to_add; $i++) {  # count from 1 to 10
            push @list, "";
         }
      }
      my $head = $title." (".$all."):";

      printf "######### %-60s #########\n", $head;
      foreach my $user (@list){
          push @linelist, $user;
          if ($#linelist==$index_number){
              if ($number==2){
    	         printf "%-36s %-36s\n", 
                 @linelist;
	     } elsif ($number==4){
 	         printf "%-18s %-18s %-18s %-18s\n", 
                 @linelist;

	     } elsif ($number==6){
	         printf "%-12s %-12s %-12s %-12s %-12s %-12s\n", 
                 @linelist;
          }
          @linelist=();
          } 
      }
      print "----------------------------------------",
            "----------------------------------------\n";
   }
}





################################################################################
# Zentrale Dateirechte
################################################################################
=pod

=item I<get_alle_verzeichnis_rechte()>

Reads all directory permissions from repair.directories and displays
puts them in a hash.

=cut
sub get_alle_verzeichnis_rechte {
   # Diese Datei liest repair-directories ein in einen Hash
   # Key: Verzeichnis, exakt so, wie es in repair.directories steht
   # Value: die entsprechende Zeile in repair.directories
   # Hash alle_verzeichnis_rechte muss global sein
   %alle_verzeichnis_rechte=();
   my $verzeichnis="";
   my $owner="";
   my $gowner="";
   my $permissions="";
   my $key="";
   my $value="";
   open(REPAIR, "<$DevelConf::devel_pfad/repair.directories");
   while (<REPAIR>) {
      chomp(); # Returnzeichen abschneiden
      s/\s//g; # Spezialzeichen raus
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($verzeichnis,$owner,$gowner,$permissions)=split(/::/);
      $alle_verzeichnis_rechte{$verzeichnis}=$_;
   }
   close(REPAIR);
   
#   if($Conf::log_level>=3){
#      # Hash ausgeben
#     while (($key,$value) = each %alle_verzeichnis_rechte){
#         printf "%-40s %40s\n","$key","-$value-";
#      }
#    }
   return %alle_verzeichnis_rechte;
}




=pod

=item I<get_alle_v_rechte()>

Liest die Rechte aus dem Hash von get_alle_verzeichnis_rechte aus
Parameter ist das Verzeichnis, so wie es in repair.directories steht
Wenn ein $-Zeichen im Parameter steht, muss das Escape-Zeichen verwendet werden

Beispiel:  

my ($owner,$gowner,$perm)=get_v_rechte("/home/lehrer/\$lehrer");

=cut
sub get_v_rechte {
   my ($key)=@_;
   if (not exists($alle_verzeichnis_rechte{$key})) {
      print "ABBRUCH: Dateirechte von $key konnten nicht ermittelt werden!\n\n";
      exit;
   } 
   my $linie=$alle_verzeichnis_rechte{$key};
   my ($verzeichnis,$owner,$gowner,$permissions)=split(/::/,$linie);
   if($Conf::log_level>=3){
      print "Verzeichnis: $verzeichnis\n";
      print "Eigentümer: $owner\n";
      print "Gruppe: $gowner\n";
      print "Rechte: $permissions\n";
    }
   my @v_rechte=($owner,$gowner,$permissions);
   return @v_rechte;
}



=pod

=item I<setup_verzeichnis(...)>

Todo

=cut
sub setup_verzeichnis {
   my ($key,$pfad,$user,$gruppe)=@_;
   # key: woher in repair.directories soll ich Rechte und owner holen
   # pfad: auf welches Verzeichnis soll angewendet werden 
   # user: mit welchem username soll $schueler bzw. $lehrer ersetzt werden
   # gruppe: mit welcher Gruppe soll $klasse ersetzt werden
   if (not exists($alle_verzeichnis_rechte{$key})) {
      print "ABBRUCH: Dateirechte von $key konnten nicht ermittelt werden!\n\n";
      exit;
   }

   if ($pfad eq ""){
      print "\nABBRUCH: Parameter 2 von setup_verzeichnis fehlt.\n\n";
      exit;
   }    
      my $linie=$alle_verzeichnis_rechte{$key};
      my ($verzeichnis,$owner,$gowner,$permissions)=split(/::/,$linie);
      
      # Ersetzungen durchführen
      # wenn mehrere duch / getrennte Dateirechte, dann erste nehmen
      if ($permissions =~m/\//) {
         ($permissions)=split(/\//,$permissions);
      }
      # $apache_user ersetzen
      $owner=~s/\$apache_user/$DevelConf::apache_user/;
      # $apache_group ersetzen
      $gowner=~s/\$apache_group/$DevelConf::apache_group/;
      # $webserver ersetzen
      $pfad=~s/\/\$webserver/$DevelConf::apache_root/;

      # group override
      if (defined $user) {
          # owner ersetzen, falls $schueler, $leher
          $owner=~s/\$schueler/$user/;
          $owner=~s/\$lehrer/$user/;
          $owner=~s/\$workstation/$user/;

          #$owner=$user;
      }

      # user override
      if (defined $gruppe) {
          # group is ALWAYS overridden, when specified in function 
          $gowner=$gruppe;
      }

    if($Conf::log_level>=3){
      print "Using Data of:      $verzeichnis\n";
      print "Owner to set:       $owner\n";
      print "Group owner to set: $gowner\n";
      print "Permissions to set: $permissions\n";
      print "Apply to:           $pfad\n";
      
    }
  
    # vorhandene Daten prüfen
   if (not -e $pfad) {
      if($Conf::log_level>=2){
        print "Creating $pfad \n";
      }
      &do_falls_nicht_testen(
        "mkdir $pfad"
      );
   } elsif (-l $pfad) {
      print "ABBRUCH: $pfad ist ein Link auf ein Verzeichnis\n";
      exit;
   } elsif (-d $pfad) {
      if($Conf::log_level>=2){
         print "Verzeichnis $pfad ist schon vorhanden\n";
       }
   } else {
      print "ABBRUCH: $pfad existiert, ist jedoch kein Verzeichnis\n\n";
      exit;
   }

   # Rechte und Owner setzen   
   if ($DevelConf::testen==0) {
     if($Conf::log_level>=2){
        print "$pfad becomes $permissions $owner.$gowner\n\n";
      }
     system("chown ${owner}.${gowner} $pfad");
     system("chmod $permissions $pfad");
   }
}



sub make_some_files_root_only {
    # if parameter is given use it as a filename
    # otherwise use list below
    my ($file) = @_;
    my @filelist=();
    if (defined $file){
       @filelist=($file);
    } else {
       # add more files here
       @filelist=("/etc/ldap.secret",
                  "/etc/ldap/slapd.conf",
                  "/etc/smbldap-tools/smbldap.conf",
                  "/etc/smbldap-tools/smbldap_bind.conf",
                  "/etc/imap.secret"
                  );
    }

    # do it
    foreach my $root_file (@filelist){
        if (-e $root_file){
            print "Making file $root_file root only\n";
            system("chown root.root $root_file");
            system("chmod 0600 $root_file");
        } else {
            print "WARNING: File $root_file does not exist, ",
                  "cannot make root only.\n";
        }
    }
}


################################################################################
#  Working with files
################################################################################

sub remove_line_from_file {
    my @fields=();
    my $found=0;
    my ($regex,$file) = @_;
    open(FILE,"<$file");
    open(TMP,">$file.tmp");
    while (<FILE>){
      chomp();
      if (/$regex/){
          $found=1;
          if($Conf::log_level>=2){
              print "   Removing: $_ \n",
                    "         in: $file!\n";
	  }
      } else {
	  print TMP "$_\n";
      }
    }
    close(FILE);
    close(TMP);
    system("mv $file.tmp $file");
    if ($found == 0){
	print "   Could not find Regex $regex \n";
    }
    return;
}



################################################################################
#  Reading Data from old installations of sophomorix 
################################################################################

sub get_old_info {
   my ($dir, $no_kclass) = @_;
   # Files
   my $protocol="${dir}/user_db";
   my $passwd="${dir}/passwd";
   my $group="${dir}/group";
   my $teach_in="${dir}/teach-in.txt";

   if($Conf::log_level>=1){
      print "I use the following old files:\n";
      print "   user.db:          $protocol\n";
      print "   teach-in.txt:     $teach_in\n";
      print "   passwd:           $passwd\n";
      print "   group:            $group\n";
   }

   # Result-hashes
   my %old_id_login=();
   my %old_login_id=();
   my %old_id_password=();  
   my %old_id_id=();  
   my %old_unix_ids=();
   my %old_group_gid=();  
   my %old_unix_gids=();
   my %old_teach_in=();
   my ($admin_class, $gecos,$login, $pass,$birth)=();
   my ($name,$surname)=();
   my ($passwd_login,$spass,$id,$gid,$passwd_gecos,$home,$shell)=();
   my ($gname,$gpass,$group_gid);
   my ($identifier_sys,$identifier_admin);

   open(TEACHINDATEN,"$teach_in") || die "Fehler: $!";
   &titel("Extracting data from old teach-in.txt ...");
   while(<TEACHINDATEN>){
      chomp();
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($identifier_sys,$identifier_admin)=split(/:::/);
      if (exists $old_teach_in{$identifier_sys}){ 
	   print "   ERROR: Identifier  $identifier_sys exists ",
                 "multiple times in old teach-in.txt.\n";
      } else {
         $old_teach_in{$identifier_sys}="$identifier_admin";
      }
   }
   close(TEACHINDATEN);

   # creating login -> unix-id hash
   open(PASSWD, "<$passwd") || die "Fehler: $!";
   &titel("Extracting data from old passwd ...");
   while(<PASSWD>){
       chomp($_);
       ($passwd_login,$spass,$id,$gid,$passwd_gecos,$home,$shell)=split(/:/);
       if (exists $old_unix_ids{$id}){
	   print "   ERROR: Unix_id $id exists ",
                 "multiple times in old passwd.\n";
       } else {
          $old_unix_ids{$id}="$passwd_login";
       }
 

       if (exists $old_login_id{$passwd_login}){
	   print "   ERROR: Loginname $passwd_login exists ",
                 "multiple times in old passwd.\n";
       } else {
          $old_login_id{$passwd_login}="$id";
       }
   }
   close(PASSWD);

   # creating identifier -> ... hashes
   open(PROTOCOL, "<$protocol") || die "Fehler: $!";
   &titel("Extracting data from old user_db ...");
   while(<PROTOCOL>){
       chomp($_);
       ($admin_class, $gecos,$login, $pass,$birth)=split(/;/);
       ($name,$surname)=split(/\ /,$gecos); 
        $identifier="$surname".";"."$name".";"."$birth";

       # adjusting identifier according to teach-in.txt
       if (exists $old_teach_in{$identifier}){
          $identifier=$old_teach_in{$identifier}
       }

       # identifier -> login hash
       $old_id_login{$identifier}="$login";
       # identifier -> password hash
       $old_id_password{$identifier}="$pass";
       # looking up id
       $id=$old_login_id{$login};
       if (not defined $id){
	   $id="";
           print "   ERROR: Account $login ($identifier) has no ",
                 "entry in old passwd.\n"; 
       } else {
         # identifier -> id hash
         $old_id_id{$identifier}="$id";
       }

   }
   close(PROTOCOL);

   # creating groupname -> unix-gid hash
   open(GROUP, "<$group") || die "Fehler: $!";
   &titel("Extracting data from old group ...");
   while(<GROUP>){
       chomp($_);
       ($gname,$gpass,$group_gid)=split(/:/);

       if ($no_kclass==0){
         # removing the leading k       
         $gname=~s/^k//;
       }

       # create the returned hash
       if (exists $old_group_gid{$gname}){
	  print "   ERROR: Groupname $gname exists ",
                "multiple times in old group.\n";
       } else {
          $old_group_gid{$gname}="$group_gid";
       }

       # just to check for double gids
       if (exists $old_unix_gids{$group_gid}){
	  print "   ERROR: Unix-gid $group_gid exists ",
                "multiple times in old group.\n";
       } else {
          $old_unix_gids{$group_gid}="$gname";
       }

   }
   close(GROUP);

   # return references to the hashes
   return(\%old_id_login,
          \%old_id_password,
          \%old_id_id,
          \%old_group_gid 
         );
}






# ===========================================================================
# Daten aus Klassen-Tauschverzeichnis ins home des Schülers kopieren
# ===========================================================================
=pod

=item I<%hash = save_tausch_klasse(login, klasse)>

Daten aus Klassen-Tauschverzeichnis ins home des Schülers kopieren

=cut

sub save_tausch_klasse {
   my ($login, $klasse) = @_;
   my $dirname=&zeit_stempel;
   my ($homedir)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
   my $dirpath="$homedir"."/"."${Language::share_string}".
               "$dirname"."/";

   my $tausch_klasse_path = "";
   if ($klasse eq ${DevelConf::teacher}) {
     $tausch_klasse_path = "${DevelConf::share_teacher}";
   } else {
     $tausch_klasse_path = "${DevelConf::share_classes}/"."$klasse";
   }
   # abs. Pfade der zu movenden Verzeichnisse im Tauschverzeichnis 
   # in eine Liste schreiben
   print "Hierher moven (Home des Schülers/lehrers): \n   $dirpath\n";
   print "Hier suchen (Klassen-Tausch/Lehrer-Tausch):\n   $tausch_klasse_path\n";

   if (not -e "$tausch_klasse_path"){
     # nit tun
   } else {
   opendir KTAUSCH, $tausch_klasse_path or 
                  die "kann $tausch_klasse_path nicht öffnen\n";

   foreach my $datei (readdir KTAUSCH){
      if ($datei eq "."){next};
      if ($datei eq ".."){next};
      my $path=("$tausch_klasse_path"."/"."$datei");
      my @statliste=lstat($path);
      my $owner = getpwuid $statliste[4];
      print "Gefunden: $datei gehört $owner\n";
      # wenn die Datei/Verzeichnis dem zu versetzenden gehört
      # Todo: UND bei Verzeichnissen kein weiterer owner unterhalb auftritt ???????
      if ($owner eq "$login") {
      # Verschieben
      if (not -e "$dirpath") {
         &do_falls_nicht_testen(
           "install -d -o$login -glehrer $dirpath"
          );
      };
            print "Verschieben: $datei (owner: $owner)\n";
        &do_falls_nicht_testen(
           "mv \"$path\" $dirpath"
        );
      }
   }
   closedir KTAUSCH;
}
}




=pod

=item I<provide_class_files(class)>

Creates all files and directories for a class (exchange/share/... directories).

=cut


sub provide_class_files {
    my ($class) = @_;
    if ($class eq ${DevelConf::teacher}){
      &setup_verzeichnis("\$share_teacher",
                    "${DevelConf::share_teacher}");
      &setup_verzeichnis("\$www_teachers",
                    "${DevelConf::www_teachers}");
    } else {
      my $klassen_homes="${DevelConf::homedir_pupil}/$class";
      my $klassen_tausch="${DevelConf::share_classes}/$class";
      my $klassen_aufgaben="${DevelConf::tasks_classes}/$class";
      my $klassen_www="${DevelConf::www_classes}/$class";
      my $ht_access_target=$klassen_www."/.htaccess";
      &setup_verzeichnis("\$homedir_pupil/\$klassen",
                    "$klassen_homes");
      &setup_verzeichnis("\$share_classes/\$klassen",
                    "$klassen_tausch");
      &setup_verzeichnis("\$tasks_classes/\$klassen",
                    "$klassen_aufgaben");
      &setup_verzeichnis("\$www_classes/\$klassen",
                    "$klassen_www");
      # create .htaccess file if nonexisting
      if (not -e $ht_access_target){
          &group_private_noupload($class);
      }
    }
}


=pod

=item I<provide_subclass_files(subclass)>

Creates all files and directories for a subclass (exchange/share/... directories).

=cut


sub provide_subclass_files {
    my ($class) = @_;
    print "Class: $class \n";
    my @appendix=("-A","-B","-C","-D");
# ?????????? create A,B,C,D (if users exist?)
    foreach my $app (@appendix){
	my $subclass="$class"."$app";
       my $subklassen_tausch="${DevelConf::share_subclasses}/$subclass";
       my $subklassen_aufgaben="${DevelConf::tasks_subclasses}/$subclass";
       print "$subklassen_tausch\n";
       print "$subklassen_aufgaben\n";
       &setup_verzeichnis("\$share_subclasses/\$subclasses",
                          "$subklassen_tausch");
       &setup_verzeichnis("\$tasks_subclasses/\$subclasses",
                          "$subklassen_aufgaben");
    }
}

=pod

=item I<provide_project_files(project)>

Creates all files and directories for a project (exchange/share/... directories).

=cut


sub provide_project_files {
    my ($project) = @_;
    my $project_tausch="${DevelConf::share_projects}/$project";
    my $project_aufgaben="${DevelConf::tasks_projects}/$project";
    my $project_www="${DevelConf::www_projects}/$project";
    my $ht_access_target=$project_www."/.htaccess";
    print "   $project_tausch\n";
    print "   $project_aufgaben\n";
    &setup_verzeichnis("\$share_projects/\$projects",
                       "$project_tausch");
    &setup_verzeichnis("\$tasks_projects/\$projects",
                       "$project_aufgaben");
    &setup_verzeichnis("\$www_projects/\$projects",
                       "$project_www");
    # create .htaccess file if nonexisting
    if (not -e $ht_access_target){
        &group_private_noupload($project);
    }
}



sub remove_project_files {
    my ($project) = @_;
    if (not defined $project){
        $project="";
    }
    if ($project eq ""){
        print "ERROR: No project given";
        return 0; 
    }
    # removing directories
    my $command="rm -rf ${DevelConf::share_projects}/$project";
    print $command,"\n";
    system("$command");  
    $command="rm -rf ${DevelConf::tasks_projects}/$project";
    print $command,"\n";
    system("$command");  
    $command="rm -rf ${DevelConf::www_projects}/$project";
    print $command,"\n";
    system("$command");  
}



=pod

=item I<provide_user_files(class)>

Creates all files and directories for a user.

=cut
sub provide_user_files {
    my ($login,$class) = @_;
    my $home="";
    my $home_class="";
    my $share_class = "";
    my $htaccess_target="";
    my $htaccess_replace= " -e 's/\@\@username\@\@/${login}/g'".
                          " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $htaccess_template="";
    my $htaccess_sed_command="";
    my $dev_null="1>/dev/null 2>/dev/null";
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($class);
    if ($class eq ${DevelConf::teacher}){
        ####################
        # teacher
        ####################
        $home = "${DevelConf::homedir_teacher}/$login";
        $www_home = "${DevelConf::homedir_teacher}/$login/www";
        $share_class = "${DevelConf::share_teacher}";
        $htaccess_template="${DevelConf::apache_templates}"."/".
                           "htaccess.teacher.private_html-template";
        $htaccess_target=$home."/private_html/.htaccess";
        $htaccess_sed_command=
            "sed $htaccess_replace $htaccess_template > $htaccess_target";
        if ($DevelConf::testen==0) {
           &setup_verzeichnis("\$homedir_teacher/\$lehrer",
                  "$home",
                  "$login");
#           &setup_verzeichnis("\$homedir_teacher/\$lehrer/windows",
#                  "$home/windows",
#                  "$login");
           &setup_verzeichnis("\$homedir_teacher/\$lehrer/cups-pdf",
                  "$home/cups-pdf",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$task_dir",
                  "$home/${Language::task_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$handout_dir",
                  "$home/${Language::handout_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$to_handoutcopy_dir",
                  "$home/${Language::to_handoutcopy_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$to_handoutcopy_dir/\$to_handoutcopy_string\$current_room",
                  "$home/${Language::to_handoutcopy_dir}/${Language::to_handoutcopy_string}${Language::current_room}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$handoutcopy_dir",
                  "$home/${Language::handoutcopy_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$handout_dir/\$handout_string\$exam",
                  "$home/${Language::handout_dir}/${Language::handout_string}${Language::exam}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$handout_dir/\$handout_string\$current_room",
                  "$home/${Language::handout_dir}/${Language::handout_string}${Language::current_room}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$handoutcopy_dir/\$handoutcopy_string\$current_room",
                  "$home/${Language::handoutcopy_dir}/${Language::handoutcopy_string}${Language::current_room}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$collected_dir",
                  "$home/${Language::collected_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$collected_dir/\$collected_string\$current_room",
                  "$home/${Language::collected_dir}/${Language::collected_string}${Language::current_room}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$collect_dir",
                  "$home/${Language::collect_dir}",
                  "$login");
#           &setup_verzeichnis(
#                  "\$homedir_teacher/\$lehrer/\$collect_dir/\$current_room",
#                  "$home/${Language::collect_dir}/${Language::current_room}",
#                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$collected_dir/\$collected_string\$exam",
                  "$home/${Language::collected_dir}/${Language::collected_string}${Language::exam}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/\$share_dir",
                  "$home/${Language::share_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_teacher/\$lehrer/private_html",
                  "$home/private_html",
                  "$login");
           &setup_verzeichnis(
                  "\$www_teachers/\$lehrer",
                  "${DevelConf::www_teachers}/$login",
                  "$login");
           if($Conf::log_level>=3){
   	       print "$htaccess_sed_command\n";
           } else {
   	       print "   modifying  $htaccess_target\n";
           }
           system("$htaccess_sed_command"); 
           chmod 0400, $htaccess_target;
           my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
	   print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
                 "${DevelConf::apache_user}($gid) to:\n     $htaccess_target\n";
           chown $uid, $gid, $htaccess_target;
        }

        # add htaccess to /var/www/people/.../user
        &user_private_upload($login);

        &create_share_link($login, $class,$class,"adminclass");
        &create_share_directory($login, $class,$class,"adminclass");
        &create_school_link($login);
    } elsif ($type eq "adminclass") { 
        ####################
        # student
        ####################
        $home_class = "${DevelConf::homedir_pupil}/$class";
        $home = "${DevelConf::homedir_pupil}/$class/$login";
        $www_home = "${DevelConf::homedir_pupil}/$class/$login/www";
        $share_class = "${DevelConf::share_classes}/$class";
        $htaccess_template="${DevelConf::apache_templates}"."/".
                           "htaccess.student.private_html-template";
        $htaccess_target=$home."/private_html/.htaccess";
        $htaccess_sed_command=
            "sed $htaccess_replace $htaccess_template > $htaccess_target";
        if ($DevelConf::testen==0) {
           &setup_verzeichnis("\$homedir_pupil/\$klassen",
                              "$home_class");
           &setup_verzeichnis("\$homedir_pupil/\$klassen/\$schueler",
                              "$home",
                              "$login");
           system("chown -R $login:${DevelConf::teacher} $home");
#           &setup_verzeichnis("\$homedir_pupil/\$klassen/\$schueler/windows",
#                              "$home/windows",
#                              "$login");
           &setup_verzeichnis("\$homedir_pupil/\$klassen/\$schueler/cups-pdf",
                              "$home/cups-pdf",
                              "$login");
           &setup_verzeichnis(
                  "\$homedir_pupil/\$klassen/\$schueler/\$task_dir",
                  "$home/${Language::task_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_pupil/\$klassen/\$schueler/\$collect_dir",
                  "$home/${Language::collect_dir}",
                  "$login");
#           &setup_verzeichnis(
#                  "\$homedir_pupil/\$klassen/\$schueler/\$collect_dir/\$current_room",
#                  "$home/${Language::collect_dir}/${Language::current_room}",
#                  "$login");
           &setup_verzeichnis(
                  "\$homedir_pupil/\$klassen/\$schueler/\$handoutcopy_dir",
                  "$home/${Language::handoutcopy_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_pupil/\$klassen/\$schueler/\$handoutcopy_dir/\$handoutcopy_string\$current_room",
                  "$home/${Language::handoutcopy_dir}/${Language::handoutcopy_string}${Language::current_room}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_pupil/\$klassen/\$schueler/\$share_dir",
                  "$home/${Language::share_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$www_students/\$schueler",
                  "${DevelConf::www_students}/$login",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_pupil/\$klassen/\$schueler/private_html",
                  "$home/private_html",
                  "$login");

           # add htaccess to private_html
           if($Conf::log_level>=3){
   	       print "$htaccess_sed_command\n";
           } else {
   	       print "   modifying $htaccess_target\n";
           }
           system("$htaccess_sed_command"); 
           chmod 0400, $htaccess_target;
           my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
	   print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
                 "${DevelConf::apache_user}($gid) to:\n     $htaccess_target\n";
           chown $uid, $gid, $htaccess_target;
           
           # add htaccess to /var/www/people/.../user
           &user_private_noupload($login);

           &create_share_link($login, $class,$class,"adminclass");
           &create_share_directory($login, $class,$class,"adminclass");
           &create_school_link($login);
         }
    } elsif ($type eq "room"){
        ####################
        # workstation
        ####################
        if ($DevelConf::testen==0) {
           $home_ws = "${DevelConf::homedir_ws}/$class";
           $home = "${DevelConf::homedir_ws}/$class/$login";
           &setup_verzeichnis("\$homedir_ws/\$raeume",
                              "$home_ws");
           &setup_verzeichnis("\$homedir_ws/\$raeume/\$workstation",
                              "$home",
                              "$login");
           system("chown -R $login:${DevelConf::teacher} $home");
#           &setup_verzeichnis("\$homedir_ws/\$raeume/\$workstation/windows",
#                              "$home/windows",
#                              "$login");
           &setup_verzeichnis(
                  "\$homedir_ws/\$raeume/\$workstation/\$task_dir",
                  "$home/${Language::task_dir}",
                  "$login");
           &setup_verzeichnis(
                  "\$homedir_ws/\$raeume/\$workstation/\$collect_dir",
                  "$home/${Language::collect_dir}",
                  "$login");
#           &setup_verzeichnis(
#                  "\$homedir_ws/\$raeume/\$workstation/\$collect_dir/\$current_room",
#                  "$home/${Language::collect_dir}/${Language::current_room}",
#                  "$login");
#           &setup_verzeichnis(
#                  "\$homedir_ws/\$raeume/\$workstation/\$handoutcopy_dir",
#                  "$home/${Language::handoutcopy_dir}",
#                  "$login");
#           &setup_verzeichnis(
#                  "\$homedir_ws/\$raeume/\$workstation/\$handoutcopy_dir/\$current_room",
#                  "$home/${Language::handoutcopy_dir}/${Language::current_room}",
#                  "$login");
         }
    } else {
        print "\nERROR: Could not determine type of $class\n\n";
    }
}




# ===========================================================================
# Protokoll-Datei lesen
# ===========================================================================

sub protokoll_linien_oldstuff {
   # Protokoll-Datei Zeilenweise in einen Hash einlesen
   my %protokoll_linien=();
   open(PROTOKOLL,"<$DevelConf::protokoll_datei");
   # Einlesen in einen Hash
     while(<PROTOKOLL>){
        # Return entfernen
        chomp();
        $protokoll_linien{$_}="";
      }
   close(PROTOKOLL);
   # Rückgabe des Hashes (key=Linie, Value nicht definiert)
   return %protokoll_linien;  
}


# ===========================================================================
# Datei extrakurse.students erzeugen aus extrakurse.txt 
# ===========================================================================
=pod

=item I<extra_kurs_schueler(tag, monat, jahr)>

Datei extrakurse.students erzeugen aus extrakurse.txt. tag, monat,
jahr soll das aktuelle Datum sein. Es werden nur Schüler derjenigen
Kurse erzeugt, deren Kusr-Ende-Datum noch nicht erreicht ist.

=cut
sub extra_kurs_schueler {
  my ($tag, $monat, $jahr) = @_;
  my $kursname;
  my $user_basisname;
  my $user_anzahl;
  my $entfern_datum;
  my $gecos;
  my $passwort;
  my $entfern_tag;
  my $entfern_monat;
  my $entfern_jahr;
  my $wunsch_login;
  my $usernummer="nix";
  my $i;
  my $i_mod;
  my $datum_epoche;
  my $entfern_datum_epoche;
  my $identifier; 
  my %generated_identifiers=();
  my %generated_kurs=();
  open(EXTRAKURSESCHUELER, ">${DevelConf::ergebnis_pfad}/extrakurse.students") 
       || die "Fehler: $!";

  open(EXTRAKURSE, "<${DevelConf::config_pfad}/extrakurse.txt") 
       || die "Fehler: $!";

  &titel("Reading ${DevelConf::config_pfad}/extrakurse.txt ...");

  while(<EXTRAKURSE>){
     my $datum="";
     chomp();
     if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
     if($_ eq ""){next}; # Bei Leerzeilen aussteigen
     print("-----------------------------------------------------------------------------\n");
     print("Extrakurs: \n$_\n");
     ($kursname, 
      $user_basisname, 
      $user_anzahl, 
      $datum, 
      $gecos, 
      $passwort,
      $entfern_datum)=split(/;/);
     ($entfern_tag, $entfern_monat, $entfern_jahr)=split(/\./, $entfern_datum);


 
     # $user_anzahl muss aus Ziffern bestehen
     if ($user_anzahl=~/[^0-9]/){
           # 
           print "\n\n\nSYNTAXFEHLER!\n";
           print "\n\n  Benutzer-Anzahl  $user_anzahl  enthält nicht nur Ziffern ";
           print "(Kurs  $kursname)\n\n";
           print "\n\n  Beheben sie diesen Fehler in /etc/sophomorix/user/extrakurse.txt\n\n";
           print "\n\n  Und starten sie das Programm neu.\n\n";
           # Programm beenden
              exit;
       }

     # Prüfen, ob entfern-Datum überschritten ist
     ## Achtung, Januar=0

     # Datum zu Programmstart (ohne Minuten und Sekunden)
     $datum_epoche=timelocal(0, 0, 0, $tag , ($monat-1), $jahr);
     if($Conf::log_level>=3){
        print("  Unix-Datum   Heute :   $datum_epoche\n");
      }
     # Datum ab dem entfernt werden soll (ohne Minuten und Sekunden)
     $entfern_datum_epoche=timelocal(0, 0, 0, $entfern_tag , $entfern_monat-1, $entfern_jahr);
     if($Conf::log_level>=3){
        print("  Unix-Entfern-Datum :   $entfern_datum_epoche\n");
      }
     # Wenn Entfern-Datum ÜBERSCHRITTEN, dann nächste Zeile
     if ($datum_epoche>$entfern_datum_epoche){
         print("  Entfern-Datum ist überschritten ...\n");
         next;
      }; # Nächste Zeile einlesen

     print("  User werden generiert ...\n");
     # Loginzeilen für den Kurs generieren
     for ($i=1;$i<=$user_anzahl;$i++){
       # Wunschlogin erzeugen
       if ($i<=9){
           $i_mod="0"."$i" # Null davorhängen
         } else {
           $i_mod=$i;      # keine Null davor
         }
       $wunsch_login="$user_basisname"."$i_mod";
       # identifier ermitteln
       $identifier="$i_mod".";"."$gecos".";"."$datum";

       #print "\n$identifier\n\n";

       # prüfen, ob identifier schon vorhanden -> Abbruch mit Info
         if (exists ($generated_identifiers{$identifier})) {
            print "\n\nFehler beim Erzeugen der Schüler des Extrakurses $kursname !\n";
            print "Erzeugt werden sollte im Kurs --$kursname-- der User-Identifier:\n\n";     
            print "    $identifier\n";
            print "\nDieser wurde jedoch im Kurs --$generated_identifiers{$identifier}-- schon erzeugt.\n";
            print "\n\nAbhilfe:\n";
            print "\nIn den beiden Zeilen der Kurse $kursname bzw. $generated_identifiers{$identifier} \n";
            print "müssen sich das gecos-Feld ($gecos) \nODER das Anlegedatum ($datum) unterscheiden.\n";
            print "Korrigieren Sie dies im noch nicht angelegten Kurs.\n";
            exit;
         }

       # prüfen, ob Kurs schon vorhanden -> Abbruch mit Info
         if (exists ($generated_kurs{$kursname})) {
            print "\n\nFehler beim Erzeugen des Kurses $kursname !\n";
            print "Der Kursname $kursname kommt in extrakurse.txt doppelt vor.\n";
            print "Korrigieren Sie dies im noch nicht angelegten Kurs.\n";
            exit;
         }

       # identifier ins Hash schreiben
       $generated_identifiers{$identifier}="$kursname";

       # uncomment to debug
       #while (($k,$v) = each %generated_identifiers) {
       #    printf "%-35s %3s\n","$k","$v";
       #}
     
       # Zeile in Datei schreiben 
       print EXTRAKURSESCHUELER ("$kursname".";".
                                "$i_mod".";".# Nummer nutzen für untersch. identifier
                                "$gecos".";".
                                "$datum".";".  # Entferndatum
                                "$wunsch_login".";".
                                "$passwort".";".
                                "\n");
      } # Ende Zeilenerzeugung

      # kursname ins Hash schreiben
      $generated_kurs{$kursname}="";

}

close(EXTRAKURSE);


close(EXTRAKURSESCHUELER);
}



# ===========================================================================
# lehrer.txt ordnen
# ===========================================================================
=pod

=item I<lehrer_ordnen()>

Liest lehrer.txt und schreibt sie tabuliert wieder.

=cut
sub lehrer_ordnen {
   my $typ="";
   my $nachname="";
   my $vorname="";
   my $datum="";
   my $wunsch_login="";
   my $erst_passwort="";
   my $lehrer_kuerzel="";
   my $quota="";
   my $mailquota="";

   my $identifier="";

   my @linien=();
   my @linien_sortiert=();
   if($Conf::log_level>=3){
      &titel("Ordne die Datei lehrer.txt ...");
   }

   open (LEHRER, "${DevelConf::users_pfad}/lehrer.txt") 
         || die "Fehler: ${DevelConf::users_pfad}/lehrer.txt \n$!";
   open (LEHRERTMP, ">${DevelConf::users_pfad}/lehrer.tmp") 
         || die "Fehler: $!";

   while(<LEHRER>) {
     chomp();
     if(/^\#/){
        # Bei Kommentarzeichen # unbearbeitet übernehmen
        print LEHRERTMP ("$_\n");
        # weiter mit nächstem Lehrer
        next;
      } 
      s/\s//g;
      # Wenn Zeile Leer, dann aussteigen
      if ($_ eq ""){
         next;
      } 
     ($typ,
      $nachname,
      $vorname,
      $datum,
      $wunsch_login,
      $erst_passwort,
      $lehrer_kuerzel,
      $quota,
      $mailquota)=split(/;/);

     if(not defined $wunsch_login){
        # go to next user when final ; is missing
        print LEHRERTMP ("$_\n");
        # next teacher
        next;
      } 

      # identifier erzeugen
      $identifier=join("",
                       ($nachname,
                       ";",
                        $vorname,
                       ";",
                        $datum));

      if($Conf::log_level>=2){
         print ("    $identifier\n");
      }
      # In lehrer.txt muss IMMER der gültige Loginname stehen (wegen Quota) 

     if ($wunsch_login eq "") {
         # gibt es lehrer schon im system, dann dort login holen
         print("\n\n\nAbbruch:\n\n");
         print("Für die Lehrerin/den Lehrer  $vorname $nachname   ",
               "ist kein Login-Name angegeben!\n\n");
         print("\n\n  Wenn   $vorname $nachname   SCHON ANGELEGT ist, ",
               "muss der im System eingetragene \n");
         print("  Login-Name auch in lehrer.txt eingetragen werden  \n\n");
         print("\n\n  Wenn   $vorname $nachname   NOCH NICHT ANGELEGT ",
               "ist, kann ein beliebiger\n");
         print("  Login-Name in lehrer.txt eingetragen werden  \n\n");
        exit;
     }

     # Füllen der Felder
     if ($erst_passwort eq "") {
         $erst_passwort="---";
     }

     if (not defined $lehrer_kuerzel) {
         $lehrer_kuerzel="usertoken";
     }

     if ($lehrer_kuerzel eq "") {
         $lehrer_kuerzel="usertoken";
     }

     if (not defined $quota) {
         $quota="quota";
     }

     if ($quota eq "") {
         $quota="quota";
     }

     if (not defined $mailquota or $mailquota eq "") {
         $mailquota="mailquota";
     }

     # geordnete Zeile ausgeben
     printf LEHRERTMP ("%-6s %-14s %-14s %-11s %-8s %-8s %-10s %-6s %-11s",
           "$typ",
           ";$nachname",
           ";$vorname",
           ";$datum",
           ";$wunsch_login",
           ";$erst_passwort",
           ";$lehrer_kuerzel",
           ";$quota",
           ";$mailquota"
           );
     print LEHRERTMP (";\n");
   }
  
   close(LEHRER);
   close(LEHRERTMP);

   open (LEHRERTMP, "<${DevelConf::users_pfad}/lehrer.tmp") 
       || die "Fehler: $!";
   while(<LEHRERTMP>) {
       # ab ins array
       push @linien, $_;
     }
   close(LEHRERTMP);
 
   # alphabetisch sortieren
   @linien = sort @linien;

   open (LEHRER, ">${DevelConf::users_pfad}/lehrer.txt") 
         || die "Fehler: $!";
     #print LEHRER ("@linien_sortiert");
   
     while (@linien) {
        $a=shift(@linien);
        print LEHRER "$a";
      }
   close(LEHRER);

   system("rm ${DevelConf::users_pfad}/lehrer.tmp");
   system("chmod 700 ${DevelConf::users_pfad}/lehrer.txt");
   if($Conf::log_level>=3){  
      &titel("... Datei lehrer.txt ist geordnet.");
   }
}




# ===========================================================================
# Zeitstempel erzeugen
# ===========================================================================
=pod

=item I<zeit_stempel()>

Gibt die Zeit zurück. Geht mit `` einfacher ToDo

=cut
sub zeit_stempel {
   my $zeit = `date +%Y-%m-%d_%H-%M-%S`;
   chomp($zeit);
   return $zeit;
}


# ===========================================================================
# recoding
# ===========================================================================

sub recode_to_ascii {
    my ($string) = @_;
    $string=~s/ /./g;
    $string=~s/ü/ue/g;
    $string=~s/Ü/ue/g;
    $string=~s/ö/oe/g;
    $string=~s/Ö/oe/g;
    $string=~s/ä/ae/g;
    $string=~s/Ä/ae/g;
    $string=~s/ß/ss/g;
    return $string;
}




# ===========================================================================
# System-Befehl ausführen
# ===========================================================================
=pod

=item I<do_falls_nicht_testen(systembefehl)>

Wenn $testen=0 ist, soll systembefehl ausgeführt werden ansonsten wird
systembefehl nur als String ausgegeben


=cut
sub do_falls_nicht_testen {
   my ($systembefehl) = "";
   my @liste = @_;
   foreach $systembefehl (@liste) {
      #print "\n\n\$testen ist $DevelConf::testen\n\n";
      if ($DevelConf::testen==0) {
         # Ausführen
         system("$systembefehl");
      } else {
         # Ausgeben
         print " * Test: $systembefehl\n";
      }
 }
}



# ===========================================================================
# Abbruchmeldung bei Fehlerhafter Optionsangabe
# ===========================================================================
=pod

=item I<check_options()>

Diese Subroutine bekommt als Argment den Parsewert der Funktion
GetOptions.  Ist dieser nicht 1, so wurde eine Fehlerhafte Option
vergeben

=cut
sub  check_options{
   my ($parse_ergebnis) = @_;
   if (not $parse_ergebnis==1){
      my @list = split(/\//,$0);
      my $scriptname = pop @list;
      print "\nYou have made a mistake, when specifying options.\n"; 
      print "See error message above. \n\n";
      print "... $scriptname is terminating.\n\n";
      exit;
   } else {
      if($Conf::log_level>=3){
         print "All options  were recognized.\n";
      }
   }

}






# ===========================================================================
# Umgang mit Dateien: anlegen, abbrechen, kopieren, ...
# ===========================================================================
=pod

=item I<check_datei_exit(file)>

Bricht mit Fehlermeldung ab, wenn die übergebene Datei nicht existiert

=cut
sub check_datei_exit {
  my ($datei) = @_;
  # Name der aufrufenden Datei ermitteln
  my @list = split(/\//,$0);
  my $scriptname = pop @list;
  if (not (-e "$datei")) {
     print "\n  The file\n\n";
     print "    $datei\n\n";
     print "  was not found.\n\n";
     print "  $scriptname is terminating!\n\n";
     &log_script_exit("$datei does not exist",
                         1,1,0,@arguments);
  } 
}



=pod

=item I<check_datei_touch(file)>

Legt leere Datei an, wenn die übergebene Datei nicht existiert

=cut
sub check_datei_touch {
  my ($datei) = @_;
  if (not (-e "$datei")) {
     &titel("Creating file $datei");
     system("touch ${datei}");
  } 
}



=pod

=item I<check_config_template(file)>

Kopiert template datei nach file, wenn file nicht existiert

=cut
sub check_config_template {
  my ($datei) = @_;
  my $etc_file=${DevelConf::config_pfad}."/".$datei;
  my $config_datei=${DevelConf::config_template_pfad}."/".$datei;
  if (not (-e "$etc_file")) {
      my $command="cp $config_datei $etc_file";
      print "   ### Creating file: \n   $command \n";
     system("$command");
  } 
}



=pod

=item I<check_verzeichnis_mkdir(dir)>

Legt Verzeichnis an, wenn nicht existiert

=cut
sub check_verzeichnis_mkdir {
  my ($verzeichnis) = @_;
  if (not (-e "$verzeichnis")) {
     if($Conf::log_level>=2){
        print "\n  Das Verzeichnis ${verzeichnis} wird angelegt \n\n";
     }
     system("mkdir ${verzeichnis}");
  } 
}









# ===========================================================================
# User Account Information
# ===========================================================================
=pod

=item I<get_user_history(login)>

Druckt die sophomorix Logfiles des users login aus 

=cut
sub get_user_history {
   my ($login) = @_;
   my @line=();
   my $count=0;
   &check_datei_touch("${DevelConf::log_files}/user-modify.log");
   open(HISTORY, 
       "<${DevelConf::log_files}/user-modify.log") 
        || die "Fehler: $!";

   while (<HISTORY>){
      chomp();
      @line=split(/::/);
      if (not defined $line[6]){$line[6]=""}
      if ($line[2] eq $login){
	 $count++;
         my $info=$line[0]."(".$line[1]."): ";
         printf "  %-27s %-49s \n",$info,$line[3];
         printf "     Unid: %-18s %-49s \n",$line[6],$line[5];
          
      }
   }
   close(HISTORY);
   if ($count==0){
       print "  No History exists.\n";
   }
}




=pod

=item I<get_group_list(login)>

Gibt die Liste der Gruppennamen zurück, in denen der user mit dem
loginnamen login ist.

=cut
sub get_group_list {
    my ($login) = @_;
    my @group_list=();
    my $pri_group_string=`id -gn $login`;
    my $group_string=`id -Gn $login`;
    chomp($group_string);
    chomp($pri_group_string);
    @group_list=split(/ /, $group_string);
    return @group_list;
}


=pod

=item I<print_forward(login,home)>

Gibt den Inhalt von .forward aus

=cut
# this sjould be true for all db and auth-systems
sub print_forward {
    my ($login, $home) = @_;
    if (-e "$home/.forward"){
       open(FORWARD,"$home/.forward");
       while (<FORWARD>){
           chomp();
	   print "  "."$_ \n";
       }
   } else {
       print "  User $login has no mail forwarding.\n";
   }
}


=pod

=item I<get_passwd_charlist()>

Gibt eine Liste aller für Zufalls-Passwörter zulässiger Zeichen zurück

=cut

sub get_passwd_charlist {
   # Zeichen, die in den verschlüsselten Passwörtern vorkommen dürfen
   # auslassen: 1,i,l,I,L,j
   # auslassen: 0,o,O
   # auslassen: Grossbuchstaben, die mit Kleinbuchstaben 
   #            verwechselbar: C,I,J,K,L,O,P,S,U,V,W,X,Y,Z 
   my @zeichen=('a','b','c','d','e','f','g','h','i','j','k',
                'm','n','o','p','q','r','s','t','u','v',
                'w','x','y','z',
                'A','B','D','E','F','G','H','L','M','N','Q','R','T',
                '2','3','4','5','6','7','8','9');
   return @zeichen;
}




=pod

=item I<get_random_password(num,group,@charlist)>

Gibt ein Zufallspasswort, zusammengesetzt aus den übergebenen Zeichen,
zurück. Ist die Länge num=0, so wird die in sophomorix.conf angegebene
Länge für die entsprechende Gruppe group benutzt.

=cut
sub get_random_password {
   my $num=shift;
   my $group=shift;
   my @chars=@_;
   my $password="";
   my $i;

   if ($group eq ${DevelConf::teacher} and $num==0){
       $num=${Conf::zufall_passwort_anzahl_lehrer};
   } elsif ($num==0){
       $num=${Conf::zufall_passwort_anzahl_schueler};
   }
   # Zufallspasswort erzeugen
   for ($i=1;$i<=$num;$i++){
      $password=$password.$chars[int (rand $#chars)];
   }
   return $password;
}

sub get_plain_password {
   my $gruppe=shift;
   my @passwort_zeichen=@_;
   my $passwort="";
   my $i;
   if ($gruppe eq ${DevelConf::teacher}) {
      # Es ist ein Lehrer
      if ($Conf::lehrer_zufall_passwort eq "yes") {
         # Zufallspasswort erzeugen
         for ($i=1;$i<=${Conf::zufall_passwort_anzahl_lehrer};$i++)
            {
              $passwort=$passwort.$passwort_zeichen[int (rand $#passwort_zeichen)];
            }
         } else {
            # Standard-Passwort verwenden
            $passwort="linux";
	  }
      } else {
         # Es ist ein Schüler
         if ($Conf::schueler_zufall_passwort eq "yes") {
            # Zufallspasswort erzeugen
            for ($i=1;$i<=${Conf::zufall_passwort_anzahl_schueler};$i++)
             {
              $passwort=$passwort.$passwort_zeichen[int (rand $#passwort_zeichen)];
             }
         } else {
            # Standard-Passwort verwenden
            $passwort="linux";
         }
       }
    return $passwort;
}



sub create_school_link {
    my ($login) = @_;
    my ($home)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
    if ($home ne ""){
       my $link_name=$home.
        "/${Language::share_dir}/${Language::share_string}".
        "${Language::school}";

       my $link_target=$DevelConf::share_school;

       # Link to school
       if($Conf::log_level>=2){
           print "   Link name (school): $link_name\n";
           print "   Target    (school): $link_target\n";
       }
       symlink $link_target, $link_name;
    }
}





sub reset_user {
    # call &get_alle_verzeichnis_rechte();
    # before reset_user
    my ($user) = @_;
    print "Cleaning up user $user\n";
    my ($homedir,$type)=
        &Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);

    if ($homedir eq ""){
        print "   ERROR: Cannot determine Homedirectory of user $user\n";
        print "   ... doing nothing!\n";
    } elsif ($type ne "student" 
         and $type ne "teacher" 
         and $type ne "workstation"){
        print "   WARNING: Cannot reset account $user \n";
        print "            Not a student, teacher or workstation\n";
    } else {
        # do some work
        my (@groups) = 
           &Sophomorix::SophomorixPgLdap::pg_get_group_list($user);
        if (-e $homedir){
            print "   Removing contents of $homedir\n";
            system("rm -rf ${homedir}/*"); 
            print "   Creating directories in $homedir\n";
            my $pri_group=shift(@groups);
            &provide_user_files($user,$pri_group);
            my ($pri_type,$pri_longname)=
               &Sophomorix::SophomorixPgLdap::pg_get_group_type($pri_group);
            &create_share_link($user,$pri_group,$pri_longname,$pri_type);
            # secondary memberships
            foreach my $group (@groups){
                if($Conf::log_level>=2){
                    print "   $user is in secondary $group\n";
                }
                my ($type,$longname)=
                   &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);
                    print "   Creating Links for secondary ",
                          "group $group ($longname)\n";

                if($Conf::log_level>=2){
                    print "   Creating Links for secondary ",
                          "group $group ($longname)\n";
                }    
                &create_share_link($user,$group,$longname,$type);
                if($Conf::log_level>=2){
                    print "   Creating Directories for secondary group $group\n";
                }
                &create_share_directory($user,$group,$longname,$type);
            }
        } else {
            print "Directory $homedir does not exist\n";
        }
    }
}





=pod

=item I<create_share_link(login,project,project_long_name,type)>

Legt Links an in:
  - das Tauschverzeichnis
  - das Aufgabenverzeichnis

Der type kann sein: project, class oder subclass

=cut
# this should be true for all db and auth-systems
sub create_share_link {
    my ($login,$share_name,$share_long_name,$type) = @_;
    my $link_target="";
    my $link_target_tasks="";
    my ($homedir,$pri_group)=
        &Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);

    # replace teachers with language term
    if ($share_name  eq ${DevelConf::teacher}){
        $share_long_name=${Language::teacher};     
    }

    # use shortname as longname if not given
    if (not defined $share_long_name){
        $share_long_name=$share_name;
    }

    # project is standard
    if (not defined $type or $type eq ""){
	$type="project";
    }

    # Only act if uid is valid
    if ($homedir ne ""){
       my $link_name=$homedir.
          "/${Language::share_dir}/${Language::share_string}".
          "${share_long_name}";   

       my $link_name_tasks=$homedir.
          "/${Language::task_dir}/${Language::task_string}".
          "${share_long_name}";
   
       if ($type eq "project"){
           # project
           $link_target="${DevelConf::share_projects}/${share_name}";
           $link_target_tasks="${DevelConf::tasks_projects}/${share_name}";
       } elsif ($type eq "adminclass"){
           # class
	   if ($share_name  ne ${DevelConf::teacher}){
               # student
               $link_target="${DevelConf::share_classes}/${share_name}";
               $link_target_tasks="${DevelConf::tasks_classes}/${share_name}";
	   } else {
               # teacher
               $link_target="${DevelConf::share_teacher}";
               $link_target_tasks="${DevelConf::tasks_teachers}";
	   }
       }elsif ($type eq "subclass"){
           # subclass
           $link_target="${DevelConf::share_subclasses}/${share_name}";
           $link_target_tasks="${DevelConf::tasks_subclasses}/${share_name}";
       }elsif ($type eq "room"){
           # room
           $link_target_tasks="${DevelConf::tasks_rooms}/${share_name}";
       } else {
           print "Unknown type $type\n\n";
	   return 0;
       }

       # make sure directory exists
#       &setup_verzeichnis("\$homedir_pupil/\$klassen/\$schueler/\$share_dir",
#                      "$homedir/${Language::share_dir}");

       # Link to share (all but workstations)
       if ($type ne "room"){
           if($Conf::log_level>=2){
               print "   Link name (share): $link_name\n";
               print "   Target    (share): $link_target\n";
           }
           if (-e $link_target and -d $link_target){
               if($Conf::log_level>=2){
                   print "   Creating link for $login ",
                         "to $type ${link_target}.\n";
               }
               symlink $link_target, $link_name;
           } else {
               print "   NOT creating Link to ",
                     "nonexisting/nondirectory $link_target\n";
           }
       }

       # Link to tasks (all users)
       if($Conf::log_level>=2){
           print "   Link name (tasks): $link_name_tasks\n";
           print "   Target    (tasks): $link_target_tasks\n";
       }
       if ($type eq "room"){
          # create the share_dir on the fly
          &setup_verzeichnis("\$tasks_rooms/\$raeume",
                             "$link_target_tasks");
       }

       if (-e $link_target_tasks and -d $link_target_tasks){
           if($Conf::log_level>=2){
               print "   Creating link user $login ",
                     "to $type ${link_target_tasks}.\n";
           }    
           symlink $link_target_tasks, $link_name_tasks;
       } else {
           print "   NOT creating Link to ",
                 "nonexisting/nondirectory $link_target_tasks\n";
       }
    } else {
        print "   NOT removing directories: ",
              "Home of user $login not known.\n";

    }
}

sub create_share_directory {
    my ($login,$share_name,$share_long_name) = @_;
    # replace teachers with language term
    if ($share_name  eq ${DevelConf::teacher}){
        $share_long_name=${Language::teacher};     
    }

    # use shortname as longname if not given
    if (not defined $share_long_name){
        $share_long_name=$share_name;
    }

    my ($homedir,$account_type)=
       &Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);

    if ($homedir ne ""){
        # create dirs in handout and collect
        if ($account_type eq "teacher"){
            ##############################
            # teacher
            ##############################
            my $handout_dir=$homedir."/".
                ${Language::handout_dir}."/".
                ${Language::handout_string}.$share_long_name;
            if (not -e $handout_dir){
                if($Conf::log_level>=2){
                    print "   Adding directory ${handout_dir}\n"; 
	        }
                system("mkdir $handout_dir");
                system("chown $login:root $handout_dir");
            }
            my $to_handoutcopy_dir=$homedir."/".
                ${Language::to_handoutcopy_dir}."/".
                ${Language::to_handoutcopy_string}.$share_long_name;
            if (not -e $to_handoutcopy_dir){
                if($Conf::log_level>=2){
                    print "   Adding directory ${to_handoutcopy_dir}\n"; 
	        }
                system("mkdir $to_handoutcopy_dir");
                system("chown $login:root $to_handoutcopy_dir");
            }
            my $collected_dir=$homedir."/".
                ${Language::collected_dir}."/".
                ${Language::collected_string}.$share_long_name;
            if (not -e $collected_dir){
                if($Conf::log_level>=2){
                    print "   Adding directory ${collected_dir}\n"; 
	        }
                system("mkdir $collected_dir");
                system("chown $login:root $collected_dir");
            }
            
            # adding subdirs with the name of $teacher to __einsammeln
#            my ($type,$longname)=
#                &Sophomorix::SophomorixPgLdap::pg_get_group_type($share_name);
#            my @groupmembers =
#                &Sophomorix::SophomorixPgLdap::pg_get_group_members($share_name);
#            foreach my $member (@groupmembers){
#                print "Adding dirs for $member ($share_name)\n";
#                my ($homedir,$account_type)=
#                   &Sophomorix::SophomorixPgLdap::fetchdata_from_account($member);
#                my $dir=$homedir."/".$Language::collect_dir."/".
#                        $longname."/".$login;
#                print "Adding $dir to $member ($share_name)\n";
#                if (not -e $dir){
#                    if($Conf::log_level>=2){
#                        print "   Adding directory ${dir}\n"; 
#	            }
#                    system("mkdir $dir");
#                }
#            }     
        }
        ##############################
        # all users
        ##############################
#        my $collect_dir=$homedir."/".
#            ${Language::collect_dir}."/".$share_long_name;
#        if (not -e $collect_dir){
#            if($Conf::log_level>=2){
#                print "   Adding directory ${collect_dir}\n"; 
#	    }
#            system("mkdir $collect_dir");
#        }
        my $handoutcopy_dir=$homedir."/".
            ${Language::handoutcopy_dir}."/".
            ${Language::handoutcopy_string}.$share_long_name;
        if (not -e $handoutcopy_dir){
            if($Conf::log_level>=2){
                print "   Adding directory ${handoutcopy_dir}\n"; 
            }
            system("mkdir $handoutcopy_dir");
            system("chown $login:root $handoutcopy_dir");
        }

    } else {
        print "   NOT creating directories: ",
              "Home of user $login not known.\n";
    }
}

=pod

=item I<remove_share_link(login,project,project_long_name)>

Löscht den Link an in das Tauschverzeichnis des Projekts.

=cut
# this should be true for all db and auth-systems
sub remove_share_link {
    my ($login,$share_name,$share_long_name,$type) = @_;
    if (not defined $type or $type eq ""){
	$type="project";
    }
    my ($homedir)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
    if ($homedir ne ""){
        my ($home)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
        my $link_name=$home.
          "/${Language::share_dir}/${Language::share_string}".
          "${share_long_name}";   
        my $link_name_tasks=$home.
          "/${Language::task_dir}/${Language::task_string}".
          "${share_long_name}";   

        # remove the link
        if($Conf::log_level>=2){
            print "   Removing link ${link_name}\n";
        }
        unlink $link_name;
        if($Conf::log_level>=2){
            print "   Removing link ${link_name_tasks}\n";
        }
        unlink $link_name_tasks;
    } else {
        print "   NOT removing links: ",
              "Home of user $login not known.\n";
    }
}



sub remove_share_directory {
    my ($login,$share_name,$share_long_name,$type) = @_;
    # replace teachers with language term
    if ($share_name  eq ${DevelConf::teacher}){
        $share_long_name=${Language::teacher};     
    }
    my ($homedir,$account_type)=
       &Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);

    if ($homedir ne ""){
        # remove dirs in tasks and collect
        if ($account_type eq "teacher"){
            ##############################
            # teacher
            ##############################
            my $handout_dir=$homedir."/".
               ${Language::handout_dir}."/".${Language::handout_dir}.
               $share_long_name;
            if (-e $handout_dir){
                if($Conf::log_level>=2){
                    print "   Removing $handout_dir if empty.\n";
                }
                system("rmdir $handout_dir");
            }
            my $to_handoutcopy_dir=$homedir."/".
               ${Language::to_handoutcopy_dir}."/".
               ${Language::to_handoutcopy_string}.$share_long_name;
            if (-e $to_handoutcopy_dir){
                if($Conf::log_level>=2){
                    print "   Removing $to_handoutcopy_dir if empty.\n";
                }
                system("rmdir $to_handoutcopy_dir");
            }
            my $collected_dir=$homedir."/".
               ${Language::collected_dir}."/".
               ${Language::collected_string}.$share_long_name;
            if (-e $collected_dir){
                if($Conf::log_level>=2){
                    print "   Removing $collected_dir if empty.\n";
                }
                system("rmdir $collected_dir");
            }

            # removing subdirs with the name of $teacher from __einsammeln
#            my ($type,$longname)=
#                &Sophomorix::SophomorixPgLdap::pg_get_group_type($share_name);
#            my @groupmembers =
#                &Sophomorix::SophomorixPgLdap::pg_get_group_members($share_name);
#            foreach my $member (@groupmembers){
#                print "Removing dirs from $member ($share_name)\n";
#                my ($homedir,$account_type)=
#                   &Sophomorix::SophomorixPgLdap::fetchdata_from_account($member);
#                my $dir=$homedir."/".$Language::collect_dir."/".
#                        $longname."/".$login;
#                if (not -e $dir){
#                    if($Conf::log_level>=2){
#                        print "   Removing directory ${dir}\n"; 
#	            }
#                    system("rmdir $dir");
#                }
#            }     
        }
        ##############################
        # all users
        ##############################
        my $collect_dir=$homedir."/".
           ${Language::collect_dir}."/".$share_long_name;
        if (-e $collect_dir){
            if($Conf::log_level>=2){
                print "   Removing $collect_dir if empty.\n";
            }
            system("rmdir $collect_dir");
        }
        my $handoutcopy_dir=$homedir."/".
           ${Language::handoutcopy_dir}."/".
           ${Language::handoutcopy_string}.$share_long_name;
        if (-e $handoutcopy_dir){
            if($Conf::log_level>=2){
                print "   Removing $handoutcopy_dir if empty.\n";
            }
            system("rmdir $handoutcopy_dir");
        }
    } else {
        print "   NOT removing directories: ",
              "Home of user $login not known.\n";
    }
}





=pod

=item I<zeit(epoche)>

Erzeugt Datum aus epochenzeit

=cut
sub zeit {
  my ($epoche)=@_;
  my $time=localtime($epoche);
  my $sekunden=$time->sec;
  my $min=$time->min;
  my $day=$time->mday;
  my $month=$time->mon+1;
  my $year=$time->year+1900;

  my $string="$day.$month.$year";
  #print "$string\n";
  return $string;
}

=pod

=item I<zeit(epoche)>

Erzeugt Datum für den Postgresql-Datentyp 'timestamp without time zone' 
aus der momentanen Zeit.

=cut
sub pg_timestamp {
  my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
  chomp($timestamp);
  return $timestamp;
}








sub append_teach_in_log {
   # appends a line to auto-teach-in.log
   my ($type,$login,$old,$new, $unid)=@_;
   my $heute=`date +%d.%m.%Y`;
   chomp($heute);
   if (not defined $unid){$unid=""} 
   open(ATLOG, 
       ">>${DevelConf::log_files}/user-modify.log") 
        || die "Fehler: $!";
   print ATLOG  $type."::".$heute."::".$login."::".
                 $old."::->::".$new."::".$unid."\n";
   close(ATLOG);

}

sub unlock_sophomorix {
    &titel("Removing lock in $DevelConf::lock_file");
    if (-e $DevelConf::lock_file){
        system("rm $DevelConf::lock_file")
    } else {
        &titel("Lock $DevelConf::lock_file did not exist");
    }
}


sub lock_sophomorix {
    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $lock="lock::${timestamp}::creator::$0";
    foreach my $arg (@arguments){
        if ($arg eq "--skiplock"){
            $skiplock=1;
        }
        if ($arg eq ""){
   	    $lock=$lock." ''";
        } else {
	    $lock=$lock." ".$arg ;
        }
    }
    $lock=$lock."::$$"."::\n";
    &titel("Creating lock in $DevelConf::lock_file");
    open(LOCK,">$DevelConf::lock_file") || die "Cannot create lock file \n";;
    print LOCK "$lock";
    close(LOCK);
}


sub log_script_start {
    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $locking_script="";
    my $skiplock=0;
    # scripts that are locking the system
    my $log="${timestamp}::start::  $0";
    my $log_locked="${timestamp}::locked:: $0";
    foreach my $arg (@arguments){
        if ($arg eq "--skiplock"){
            $skiplock=1;
        }
        if ($arg eq ""){
   	    $log=$log." ''";
   	    $log_locked=$log_locked." ''";
        } else {
	    $log=$log." ".$arg ;
	    $log_locked=$log_locked." ".$arg ;
        }
    }

    $log=$log."::$$"."::\n";
    $log_locked=$log_locked."::$$"."::\n";

    open(LOG,">>$DevelConf::log_command");
    print LOG "$log";
    close(LOG);

    # exit if lockfile exists
    if (-e $DevelConf::lock_file and $skiplock==0){
        my @lock=(); 
        open(LOCK,"<$DevelConf::lock_file") || die "Cannot create lock file \n";;
        while (<LOCK>) {
            @lock=split(/::/);
        }
        close(LOCK);
        open(LOG,">>$DevelConf::log_command");
        print LOG "$log_locked";
        close(LOG);
        $locking_script=$lock[3];
        $locking_pid=$lock[4];
        
        &titel("sophomorix locked (${locking_script}, PID: $locking_pid)");
        &titel("try again later ...");
        exit;
    }
    if (exists ${DevelConf::lock_scripts}{$0}){
	&lock_sophomorix(@arguments);
    }
}

sub log_script_end {
    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $log="${timestamp}::end  ::  $0";
    foreach my $arg (@arguments){
	$log=$log." ".$arg ;
    }
    $log=$log."::"."$$"."::\n";
    open(LOG,">>$DevelConf::log_command");
    print LOG "$log";
    close(LOG);
    # remove lock file
    if (-e $DevelConf::lock_file
         and exists ${DevelConf::lock_scripts}{$0}){
	unlink $DevelConf::lock_file;
        &titel("Removing lock in $DevelConf::lock_file");    
    }
    &titel("$0 terminated regularly");
}

sub log_script_exit {
    my $message=shift;
    # return 0: normal end, return=1 unexpected end 
    my $return=shift;
    my $unlock=shift;
    my $skiplock=shift;

    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $log="${timestamp}::exit ::  $0";
    foreach my $arg (@arguments){
	$log=$log." ".$arg ;
    }
    $log=$log."::"."$$"."::$message\n";
    open(LOG,">>$DevelConf::log_command");
    print LOG "$log";
    close(LOG);
    # remove lock file
    if (-e $DevelConf::lock_file
         and exists ${DevelConf::lock_scripts}{$0}){
        &titel("Removing lock in $DevelConf::lock_file");    
	unlink $DevelConf::lock_file;
    }
    if ($message ne ""){
        &titel("$message");
    }
    exit;
}


sub archive_log_entry {
    my ($login) = @_;
    my $file="${DevelConf::log_files}/user-modify.log";
    my $archive="${DevelConf::log_files}/user-modify-archive.log";
    my $today=`date +%d.%m.%Y`;
    chomp($today);

    &check_datei_touch($archive);

    print "File LOG is $file\n";
    open(LOG,"<$file");
    open(TMPLOG,">$file.tmp");
    open(ARCHIVE,">>$archive");
    while (<LOG>){
        chomp();
        my @line=split(/::/);
        if ($line[2] eq $login){
	   print "  Archiving log of user $line[2]\n";
    	   print ARCHIVE "$_\n";
        } else {
	   print "  $line[2] not ready for archive.\n";
    	   print TMPLOG "$_\n";
        }

    }

    print ARCHIVE "user archived::".$today."::".$login."::\n";
    system("mv $file.tmp $file");
    close(LOG);
    close(TMPLOG);
    close(ARCHIVE);
}








=pod

=item I<zeit(epoche)>

Makes a Backup ...???

=cut
sub backup_amk_file {
    my ($time, $str, $str2, $com) = @_;
    if (not defined $com){
	$com="cp";
    }
    my $inp=${DevelConf::ergebnis_pfad};
    my $outp=${DevelConf::log_pfad};
    # Verarbeitete Datei mit Zeitstempel versehen
    &do_falls_nicht_testen(
      "$com ${inp}/sophomorix.${str} ${outp}/${time}.sophomorix.${str}-${str2}",
      # Nur für root lesbar machen
      "chown root:root ${outp}/${time}.sophomorix.${str}-${str2}",
      "chmod 600 ${outp}/${time}.sophomorix.${str}-${str2}"
    );
}



################################################################################
# WORKSTATIONS
################################################################################


################################################################################
# KLASSEN
################################################################################


################################################################################
# RÄUME
################################################################################


################################################################################
# MAIL
################################################################################

# ===========================================================================
# Mail-alias aus /etc/mail/aliases ermitteln
# ===========================================================================
#
sub get_mail_alias_from {
   my ($username, $param) = @_;
   if (not defined $param) {
       $param="";
   }

   my $begin_automatisch=0;
   my @liste=();
   if ($param eq "liste") {
      # jede Zeile durchsuchen, auch manuell konfigurierte
      $begin_automatisch=1;
   }

   open(ALIASES, "</etc/mail/aliases");
      while (<ALIASES>) {
          # Erste ab dieser Zeile beginnen
          if(/^\# Automatisch erzeugt:/){$begin_automatisch=1}

          if ($begin_automatisch==1) {
             # wenn die Automatischen Einträge erreicht sind
             s/\s//g; # Spezialzeichen raus
             if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
             if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
             if(not /:/){next;} # Bei fehlendem Doppelpunkt aussteigen

             # gültige Zeilen untersuchen
             my($alias, $login)=split(/:/);

             if (not defined $username) {
               # ungültige Zeile/Listenzeile/kein Parameter übergeben
                return "";
                close(ALIASES);
                exit;
             }

             if ($login eq $username) {
                #print "$alias";
	       if ($param eq "liste") {
                   push @liste, $alias;     
	       } else {
                   return $alias;
                   close(ALIASES);
                   exit; 
	      }
             }
          }

      }

   close(ALIASES);
   if ($param eq "liste") {
      return @liste;
    } else {
      # wenn nichts gefunden, dann username zurückgeben
      return $username;
    }


}



################################################################################
# IMAP
################################################################################

sub imap_connect {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}. ",
              "Skipping IMAP stuff.\n";
        return 0;
    }
    my ($server, $admin) = @_;
    my $imap_pass="";
    # fetch pass from file
    if (-e ${DevelConf::imap_password_file}) {
         # looking for password
 	 open (CONF, ${DevelConf::imap_password_file});
         while (<CONF>){
             chomp();
             if ($_ ne ""){
		 $imap_pass=$_;
                 last;
             }
         }
         close(CONF);
    }
    if($Conf::log_level>=2){
        # $imap_pass holds password
        print "Connecting to imap-server at $server as $admin with password *** \n";
    }
    my $imap = IMAP::Admin->new(
	     'Server' => $server,
	     'Login' => $admin,
	     'Password' => $imap_pass,
	     'CRAM' => 2,
	    );
    my $status = $imap->error;      
    if ($status ne 'No Errors') {
        print "$status \n";
	$imap->close();
	return undef;
    }
    return $imap;
}


sub imap_disconnect {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}. ",
              "Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap) = @_;
    
    if($Conf::log_level>=2){
        print "Disconnecting from imap-server ... \n";
    }
    $imap->close();
}


sub imap_show_mailbox_info {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}.",
              " Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap) = @_; 
    my @mailboxes = $imap->list("user.*"); # one entry per dir
    my @mailboxes_cleaned=(); # one entry per user
    my %hash=();
    my $dircount=0;
    foreach my $entry (@mailboxes){
        # remove doubles
        my ($string1,$string2)=split(/\./,$entry);
        $entry=$string1.".".$string2;
        if (not exists $hash{$entry}){
	   # print "Add $entry \n";
           $hash{$entry}=1;
        } else {
	    $hash{$entry}=$hash{$entry}+1;
        }
    }
    while (my ($key) = each %hash){
        push @mailboxes_cleaned, $key;
    }
    print "+----------------------------+------+",
          "--------------------+-------------+\n";
    printf "| %-27s| %4s | %-19s| %12s|\n",
           "Mailbox","Dirs", "Used Mailquota","Mailquota";
    print "+----------------------------+------+",
          "--------------------+-------------+\n";
    @mailboxes_cleaned = sort @mailboxes_cleaned;
    foreach my $box (@mailboxes_cleaned){
	#print $box,"\n";
        my @data=&imap_fetch_mailquota($imap,$box,1,1);
        printf "| %-27s| %4s | %-19s| %12s|\n",
               $data[0],$hash{$data[0]},"$data[1] MB","$data[2] MB";
    }
    print "+----------------------------+------+",
          "--------------------+-------------+\n";
}


sub imap_create_mailbox {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}.",
              " Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap,$login) = @_;
    my $err = $imap->create("user.$login");
    if ($err != 0) {
       	my $status = $imap->error;
       	#$imap->close();
        #print "Error creating mailbox for $login \n";
        if ($status=~/Mailbox already exists/){
            print "    Mailbox of $login existed already ... doing nothing.\n";
            return 1;
        } else {
            print "$status \n";
            return undef;
	}
    }
    print "Mailbox for $login created.\n";
###	create_subfolders($imap, $login, @subfolders) or return undef;
    return 1;
}


sub imap_kill_mailbox {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}.",
              " Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap,$login) = @_;
    print "Killing mailbox of ${login}.\n";
    print "   Getting list of ${login}'s mailboxes for deletion.\n";
    my @mboxes = $imap->list("user.$login.*");	# subfolders
    push @mboxes, "user.$login";			# add the root mailbox
    foreach my $mbox (@mboxes) {
        print "   Setting ACL of $mbox for removal\n";
	my $err = $imap->set_acl("$mbox", $DevelConf::imap_admin, 'c');
	if ($err != 0) {
       	my $status = $imap->error;
            if ($status=~/Mailbox does not exist/){
	        print "   Mailbox of $login does not exist ... nothing to do.\n";
                return 1;
            } else {
                print "$status \n";
		return undef;
	    }
	}
    }
    my $err = $imap->h_delete("user.$login");
    if ($err != 0) {
       	my $status = $imap->error;
#      	print "$status \n";
       	$imap->close();
       	return undef;
    }
    $imap->close();
    return 1;
}


sub imap_fetch_mailquota {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}.",
              " Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap,$user,$full_boxname,$quiet) = @_;
    my $mailbox;

    if (not defined $full_boxname){
        $full_boxname=0;
    }
    if (not defined $quiet){
        $quiet=1;
    }
    if ($full_boxname==0){
        $mailbox="user.".$user;
    } else {
        $mailbox=$user;
    }

    my @mailquota = $imap->get_quotaroot($mailbox);

    if (defined $mailquota[1]) {    
        $mailquota[1]=$mailquota[1]/1024;
        $mailquota[1]=$mailquota[1];
    } else {
        return undef;
    }

    if (defined $mailquota[2]) {    
        $mailquota[2]=$mailquota[2]/1024;
        $mailquota[2]=$mailquota[2];
    } else {
        return undef;
    }

    # cut away after 3rd 
    $mailquota[1]=int(($mailquota[1]*1000)+0.5)/1000;

    # loglevel
    if ($quiet==0){
        print "User $user ($mailquota[0]) has ",
              "used $mailquota[1] MB of $mailquota[2] MB\n";
    }
    return @mailquota;
}


sub imap_set_mailquota {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}.",
              " Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap, $login, $mailquota) = @_;
    my $mailquota_kb = $mailquota * 1024; # quota in KB

    my $err = $imap->set_quota("user.$login", $mailquota_kb);
    if ($err != 0) {
      	my $status = $imap->error;
       	return undef;
    }
    print "  set mailquota of $login to $mailquota MB\n";
    return 1;
}





################################################################################
# QUOTA
################################################################################
=pod

=item I<quota_addition(qutastring1, quotastring2, quotastring3, ...)>

Zählt quota zusammen. Nicht alle formate weden unterstützt

=cut
sub quota_addition {
    my @quotalist = @_;
    my $fs_quotalist=();
    my $sum="";
    my @resultlist=();
    my $count;
    foreach $quotastring (@quotalist) {
        # aufsplitten einer einzelnen Angabe
	@fs_quotalist=split ((/\+/,$quotastring));
        $count=0;
	foreach my $fs_quota (@fs_quotalist) {
           if (not defined $resultlist[$count]) {
	      $resultlist[$count]=0;
	   }
           $resultlist[$count]=$resultlist[$count]+$fs_quota;
           $count++;
        }
        print $sum;
    }
    foreach my $fsq (@resultlist){
       if ($sum eq ""){
	 $sum=$fsq;
       } else {
         $sum=$sum."+".$fsq;
       }
    }
    return $sum;
}





sub checked_quotastring {
   # input 1: string, der in Quotaangaben stehen kann:
   # Bsp.     156      1332+132  x-12-x-x+23
   # input 2: Dateiname für Fehlermeldung
   # input 3: Zeile, oder ähnliches, um Fehler zu finden
   my ($quota_string, $datei, $zeile)=@_;
   my @quota_liste=();
   my @quota_filesystems=&get_quota_fs_liste();
   my $quota_fs_anzahl=$#quota_filesystems+1;

   # aufsplitten am plus 
   @quota_liste=split(/\+/, $quota_string);

         if ($#quota_filesystems!=$#quota_liste){
             print "\n#########################################################\n",
                   "########## Abbruch: $datei nicht korrekt: ##########\n",
                   "#########################################################\n\n",
                   " Zeile: $zeile\n\n",
                   "Es müssen bei ALLEN Usern für $quota_fs_anzahl Dateisystem(e)",
                   " Quotaangaben gemacht werden.\n\n";
             if ($datei ne "quota.txt") {
             print "(in schulinfo.txt oder lehrer.txt kann auch das Wort 'quota' stehen).\n\n";
	   }
             exit; # Abbruch
         }

   foreach $quotawert (@quota_liste) {
      # Minux-Anzahl prüfen
      my $minus_anzahl=$quotawert=~tr/-//;
      if ($minus_anzahl == 3) {
          # Angabe mit 3 -
          my @qwert_liste=split(/-/, $quotawert);
          if ((not $qwert_liste[0]=~/[^0-9]/ or $qwert_liste[0] eq "x")
           and (not $qwert_liste[1]=~/[^0-9]/)
           and (not $qwert_liste[2]=~/[^0-9]/ or $qwert_liste[2] eq "x")
           and (not $qwert_liste[3]=~/[^0-9]/ or $qwert_liste[3] eq "x")
           ){
             # Alles OK
          } else {
             print "\n#########################################################\n",
                   "########## Abbruch: $datei nicht korrekt: ##########\n",
                   "#########################################################\n\n";
             print " $quotawert ist Fehlerhaft\n\n";
             print " Zeile: $zeile\n\n";
             exit;
          }

      } elsif ($minus_anzahl == 0){
          # Angabe ohne -

      } else {
        # Weder 0 noch 3 Minusse
        print "Fehler: Es müssen keine oder 3 Minusse in $quota_string vorhanden sein!\n";
        exit;
      }
  

 }
   
   #print "String: $quota_string Liste: @quota_liste\n";
   return @quota_liste;
}


# ===========================================================================
# Quota ermitteln
# ===========================================================================
sub get_quotastring {
   my $quotastring="";
   my $user_db_quota_entry="";
   my ($user,$fsliste, $quotaliste)=@_;
   # Nun die Elemente der Dateisystem-Liste durchgehen von 1 bis j

   for ($j=0; $j < @$fsliste; $j++){
      # Aus der Listenreferenz das j-te Element herausnehmen
      $quotastring = $quotaliste->[$j];
      $fs = $fsliste->[$j];

      # Leerzeichen aus quotastring entfernen und return abschneiden
      chomp($quotastring);
      $quotastring=~s/ //g;
      if ($user_db_quota_entry eq "") {
         $user_db_quota_entry=$quotastring;
     } else {
         $user_db_quota_entry=$user_db_quota_entry."+".$quotastring;
     }
  }
  print("Quota of user $user: $user_db_quota_entry\n");
   return $user_db_quota_entry;
}


# ===========================================================================
# Quota setzen
# ===========================================================================
   # $userkey:                             username
   # \@quota_filesystems                   Referenz auf Liste mit filesystemen
   # \@{ $login_quota_hash{$userkey} }     Referenz auf den Key $userkey im 
   # Hash %login_quota_hash, der Referenz auf Liste mit Quota enthält   
   # Beispiel: &setze_quota($userkey , 
   #                        \@quota_filesystems, 
   #                        \@{ $login_quota_hash{$userkey} } );
sub setze_quota {
   # neue, private Variablen für diesen Block anlegen
   my $quotastring="";
   my $minus_anzahl=0;
   # Optionen für den setquota-Befehl
   my $q_opt1="";
   my $q_opt2="";
   my $q_opt3="";
   my $q_opt4="";
   my $fs; 
   my $j=0;
   my $uidnumber=-1;
   # Parameter 
   # $user:        username
   # $fsliste      Referenz auf Liste mit Filesystemen (für alle user gleich)
   # $quotastring  Referenz auf Liste mit Quota (für übergebenen user)
   my ($system,$user,$fsliste, $quotaliste)=@_;
   # Nun die Elemente der Dateisystem-Liste durchgehen von 1 bis j
   for ($j=0; $j < @$fsliste; $j++){

      # Aus der Listenreferenz das j-te Element herausnehmen
      $quotastring = $quotaliste->[$j];
      $fs = $fsliste->[$j];

      # Leerzeichen aus quotastring entfernen und return abschneiden
      chomp($quotastring);
      $quotastring=~s/ //g;

      # falls Minus-Zeichen vorhanden, aufsplitten
      if ($quotastring=~/-/) {
         # quotastring aufsplitten
         ($q_opt1,$q_opt2,$q_opt3,$q_opt4)=split(/-/,$quotastring);
      } else {
         # sonst ist nur Ziffer vorhanden, also Werte setzen
         $q_opt1="x";
         $q_opt2=$quotastring;
         $q_opt3="x";
         $q_opt4="x";
      }
      # Prüfen, ob x angegeben ist
      # x im ersten Parameter
      if ($q_opt1 eq "x"){
        # Softlimit ca. 20% unter Hardlimit
        $q_opt1=$q_opt2-int($q_opt2/5);
      }
      # x im zweiten Parameter
      if ($q_opt2 eq "x"){
        # Fehler und Abbruch
        print ("\n\nHardlimit darf nicht mit x angegeben werden!\n\n");
        die;
      }
      # x im dritten Parameter
      if ($q_opt3 eq "x"){
        # 80% des Hardlimits
        $q_opt3=80*$q_opt2;
      }
      # x im vierten Parameter
      if ($q_opt4 eq "x"){
        # Wenn Dateien durchschnittlich unter 10kB/Datei gibts Probleme
        $q_opt4=100*$q_opt2;
      }

      # Quota-Befehlsparameter ausgeben
      # user-ID ermitteln
      ($a,$a,$a,$a,$uidnumber)=
         &Sophomorix::SophomorixPgLdap::fetchdata_from_account("$user");
      #($a,$a,$uidnumber)=getpwnam("$user");
#      if (not defined $uidnumber) {
#        $uidnumber=999999;
#        print("UserID:   n.A., da Testlauf (UID=$uidnumber, show must go on.)\n");
#      }
      if($Conf::log_level>=3){
         # Ausgeben der ermittelten werte
         print("  Device:            ${fs}\n");
         print("  User:              ${user}\n");
         print("  UserID:            $uidnumber\n");
         print("  Block-Softlimit:   ${q_opt1}000  \n");
         print("  Block-Hardlimit:   ${q_opt2}000  \n");
         print("  Inode-Softlimit:   ${q_opt3}     \n");
         print("  Inode-Hardlimit:   ${q_opt4}     \n");
      }

      # Mit setquota die Quota der user tatsächlich anpassen
      if (not $DevelConf::system==1){
         # Quota-Modul benutzen
         if(not $DevelConf::testen==1) {
            # do it
            Quota::setqlim($fs,$uidnumber,"${q_opt1}000","${q_opt2}000",$q_opt3,$q_opt4);
	 } else {
            # test
            print "  Test (quota are not set!): \n";
         }
         print "   Setting quota ($fs, uid $uidnumber): "; 
         print "${q_opt1}000 ${q_opt2}000 $q_opt3 $q_opt4 \n";
      } else {
         # Systembefehl benutzten
         $quota_befehl="setquota -u ${user} ${q_opt1}000 ".
                       "${q_opt2}000 ${q_opt3} ${q_opt4} ${fs}";
         if(not $DevelConf::testen==1) {
            # do it
            system("${quota_befehl}")
         } else {
            # test
            print "  Test (quota are not set!): \n";
         }
         print("   Quota command: ${quota_befehl}","\n");
      } 
   # Quota aufsummieren
#   $DevelConf::q_summe[$j]=$DevelConf::q_summe[$j]+$q_opt2;
   }
}




# vgl. setze quota, unnötiges weggelassen
sub addup_quota {
   my $quotastring="";
   # Optionen für den setquota-Befehl
   my $q_opt1="";
   my $q_opt2="";
   my $q_opt3="";
   my $q_opt4="";
   my $fs; 
   my $j=0;
   my $uid=-1;

   # Parameter 
   # $user:        username
   # $fsliste      Referenz auf Liste mit Filesystemen (für alle user gleich)
   # $quotastring  Referenz auf Liste mit Quota (für übergebenen user)
   my ($system,$user,$fsliste, $quotaliste)=@_;
   # Nun die Elemente der Dateisystem-Liste durchgehen von 1 bis j
   for ($j=0; $j < @$fsliste; $j++){

      # Aus der Listenreferenz das j-te Element herausnehmen
      $quotastring = $quotaliste->[$j];
      $fs = $fsliste->[$j];

      # Leerzeichen aus quotastring entfernen und return abschneiden
      chomp($quotastring);
      $quotastring=~s/ //g;

      # falls Minus-Zeichen vorhanden, aufsplitten
      if ($quotastring=~/-/) {
         # quotastring aufsplitten
         ($q_opt1,$q_opt2,$q_opt3,$q_opt4)=split(/-/,$quotastring);
      } else {
         # sonst ist nur Ziffer vorhanden, also Werte setzen
         $q_opt2=$quotastring;
      }
      # x im zweiten Parameter
      if ($q_opt2 eq "x"){
        # Fehler und Abbruch
        print ("\n\nHardlimit darf nicht mit x angegeben werden!\n\n");
        die;
      }

      # Quota-Befehlsparameter ausgeben
      # user-ID ermitteln
      ($a,$a,$a,$a,$uid)=
         &Sophomorix::SophomorixPgLdap::fetchdata_from_account("$user");
#      ($a,$a,$uid)=getpwnam("$user");
#      if (not defined $uid) {
#        $uid=999999;
#        print("UserID:   n.A., da Testlauf (UID=$uid, show must go on.)\n");
#      }
     # Quota aufsummieren
     $DevelConf::q_summe[$j]=$DevelConf::q_summe[$j]+$q_opt2;
   }
   return @sum;
}









# ===========================================================================
# Hash mit standard_quota ermitteln
# ===========================================================================
sub get_standard_quota {
   my %standard_quota_hash=();
   my @soll_quota_liste=();
   my @quota_filesystems=&get_quota_fs_liste();   

   my $user="";
   my $soll_quota=0;
   open(QUOTASOLL,"${DevelConf::config_pfad}/quota.txt") || die "Fehler: $!";
   while(<QUOTASOLL>){
      chomp();
      s/\s//g; # Whitespace Entfernen
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      # user von sollquota splitten
      ($user,$soll_quota)=split(/:/);
      @soll_quota_liste = &checked_quotastring($soll_quota, "quota.txt", $_);
      # Zum Login-Quota-Hash dazunehmen
      $standard_quota_hash{$user}=[@soll_quota_liste];
   }
   close(QUOTASOLL);

   # Für jeden User in quota.txt die Quota auf allen Filesystemen ausgeben
   if($Conf::log_level>=3){
      &titel("Extrahierte Werte aus quota.txt :");
      for my $users ( keys %standard_quota_hash ) {
         printf "%-40s %8s MB\n","$users (Sollwert)","@{ $standard_quota_hash{$users} }";
       }
      print "\n";
   }
   # Rückgabe-Hash enthält standard-quota UND Einzel-Quota
   return %standard_quota_hash;
}



# ===========================================================================
# Hash mit lehrer_quota ermitteln
# ===========================================================================
sub get_lehrer_quota {
   my @quota_filesystems=&get_quota_fs_liste(); 
   my %lehrer_quota_hash=();
   my @lehrer_quota_liste=();
   my ($gruppe,
       $nachname,
       $vorname,
       $datum,
       $login_lehrer,
       $passwort,
       $kuerzel,
       $lehrer_quota,
       $email_sender,
       $email_alias)=();

   open(LEHRER,"${DevelConf::users_pfad}/lehrer.txt") || die "Fehler: $!";
   while(<LEHRER>){
      chomp();
      s/\s//g; # Whitespace Entfernen
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($gruppe,
       $nachname,
       $vorname,
       $datum,
       $login_lehrer,
       $passwort,
       $kuerzel,
       $lehrer_quota,
       $email_sender,
       $email_alias)=split(/;/);
       # Wenn Quotaangabe vorhanden, dann benutzen
       if($lehrer_quota ne "quota"){
         @lehrer_quota_liste = &checked_quotastring($lehrer_quota, "lehrer.txt", $_);
         $lehrer_quota_hash{$login_lehrer}=[@lehrer_quota_liste];
      }
   }
   close(LEHRER);

   # Für Lehrer mit Sonderquota die Quota auf allen Filesystemen ausgeben
   if($Conf::log_level>=3){
      &titel("Extrahierte Werte aus lehrer.txt :");
      for my $users ( keys %lehrer_quota_hash ) {
         printf "%-40s %8s MB\n","$users (Sollwert)","@{ $lehrer_quota_hash{$users} }";
       }
      print "\n";
   }
   # Rückgabe-Hash enthält key=lehrer-login, value=quotaliste 
   return %lehrer_quota_hash;
}





# ===========================================================================
# Hash mit klassen_quota ermitteln
# ===========================================================================


#   # Rückgabe-Hash enthält key=klassen-name, value=quotaliste 
#   return %standard_quota_hash;

# ===========================================================================
# Quotierte Dateisysteme ermitteln
# ===========================================================================
# Ermittle aus /etc/mtab die momentan benutzten Quota-Dateisysteme 
# (z.B /dev/hda4) und deren Mountpoint
# Dazu ist das Quota-Modul erforderlich
sub get_quota_fs_liste {
   my @quota_fs=();

   Quota::setmntent();
   while (($dev, $path, $type, $opts) = Quota::getmntent()) {
      #print"$dev $path $type $opts<p>";
      if ($opts=~/usrquota/){
       #print"$dev $path $type $opts hinzugenommen<p>";
       push(@quota_fs, $dev)
      }

   }
   Quota::endmntent();

   #print "Quota-Filesysteme(Liste):  @quota_fs";

   return @quota_fs;
}



sub get_quota_fs_num {
   # get number of quoted filesystems
   if ($Conf::quota_filesystems[0] eq "auto" && 
      not $Conf::quota_filesystems[2] ) {
      # AUTOMATISCH bei String "auto" in sophomorix.conf
      @quota_fs=&get_quota_fs_liste();
   } else {# NICHT AUTOMATISCH falls Vorgabe in sophomorix.conf
      @quota_fs=@Conf::quota_filesystems;
   }
   # Anzahl der zu quotierenden Dateisysteme ermitteln
   my $quota_fs_num=$#quota_fs+1;
   return $quota_fs_num;
}



# check if the given string is correct
sub check_quotastring {
    my @result=(-2); 
    # if $result[0] stays -2 its OK
    # if $result[0] gets -3 its NOT OK

    # how many filesystems
    my $quota_fs_num=shift;
    # the quotastring to check
    my ($quotastring) = @_;

    # accept 'quota' as correct
    if ($quotastring eq "quota"){
        $result[1]="quota";
        return @result;
    }

    my @list = split(/\+/, $quotastring);
    my $item=$#list+1;
    if($Conf::log_level>=2){
       print "  Checking $quotastring \n";
    }
    if (not $item==$quota_fs_num){
	print "$item quotas for $quota_fs_num filesystems\n";
        @result=(-3);
    }
    foreach my $quo (@list){
      if($Conf::log_level>=3){
         print "    Checking $quo ";
      }
      if ($quo=~/^[0-9]+$/){
         if($Conf::log_level>=3){
             print " OK\n";
         }    
      } else {
        if($Conf::log_level>=3){
            print " NOT OK\n";
        }
        @result=(-3);    
      }
    }
    if (not $result[0]==-3){
	@result=@list;
    }
    return @result;
}



################################################################################
# PASSWORT-TOOLS
################################################################################
sub sophomorix_passwd {
   my ($user,$passwd) = @_;
   if ($DevelConf::testen==0) {
      # kein Test
      if($Conf::log_level>=3){
         print "sophomorix_passwd:  Setze Passwort von $user auf $passwd\n";
      } 
      # pw verschluesseln
      open(PASSWD,"| /usr/sbin/chpasswd");
        print PASSWD "$user:$passwd\n";
      close(PASSWD);
      # smbpasswd:  -s = silent, (-a entfernt, da user schon da)
      open(SMBPASSWD,"| /usr/bin/smbpasswd -s $user");
        # Passwort in smbpasswd setzen
        print SMBPASSWD "$passwd\n$passwd\n"; 
      close(SMBPASSWD);
    } else {
       if($Conf::log_level>=3){
          print "(Test) sophomorix_passwd:  Setze Passwort von $user auf $passwd\n";
       } 
    }
}




################################################################################
# TEACHER STUFF
################################################################################

sub share_access {
    # first parameter: 0=off, 1=on
    # second parameter: list of users (also works for teachers)
    my ($share) = shift;
    my $on_off="";
    my $permission="";
    if ($share==0){
	$on_off="off";
        # change repair.directories permissions also, if you change here
        $permission="1750";
    } else {
	$on_off="on";
        # change repair.directories permissions also, if you change here
        $permission="1755";
    }
    my @users = @_;
    foreach my $user (@users){
        my ($home)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
        if ($home ne ""){
           my $share_path=$home."/".${Language::share_dir};
           print "   Setting  permissions of $share_path to $on_off($permission)\n";
           chmod oct($permission), $share_path;
       } else {
           print "$user is not a valid user\n";
       }
    }
}





sub handout {
  # Parameter 1: User that hands out data
  # Parameter 2: Name of class/subclass/project
  # Parameter 3: Typ (class,subclass,project,room, ...)
  # Parameter 4: option delete rsync
  my ($login, $name, $type, $rsync) = @_;

  # home ermitteln
  my ($homedir)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
  my $from_dir = "";

  if ($type eq "adminclass"){
      $from_dir = "${homedir}/${Language::handout_dir}/".
                  "${Language::handout_string}${name}/";
      $to_dir="${DevelConf::tasks_classes}/${name}/${login}";
  } elsif ($type eq "subclass"){
      $from_dir = "${homedir}/${Language::handout_dir}/".
                  "${Language::handout_string}${name}/";
      $to_dir="${DevelConf::tasks_subclasses}/${name}/${login}";
  } elsif ($type eq "project"){
      # get the longname
      my ($longname)=&Sophomorix::SophomorixPgLdap::fetchinfo_from_project($name);
      $from_dir = "${homedir}/${Language::handout_dir}/".
                  "${Language::handout_string}${longname}/";
      $to_dir="${DevelConf::tasks_projects}/${name}/${login}";
  } elsif ($type eq "room"){
      $from_dir = "${homedir}/${Language::handout_dir}/".
                  "${Language::handout_string}${Language::exam}/";
      $to_dir="${DevelConf::tasks_rooms}/${name}/${login}";
  }

  print "   From: ${from_dir}\n";
  print "   To:   ${to_dir}\n";

  if ($rsync eq "delete") {
     system("rsync -tor --delete $from_dir $to_dir");
     system("chmod -R 0755 $to_dir");
  } elsif ($rsync eq "copy"){
     system("rsync -tor $from_dir $to_dir");
     system("chmod -R 0755 $to_dir");
  } else {
      print "unknown Parameter $rsync";
  }


}




sub handoutcopy {
    # Parameter 1: User that hands out data
    # Parameter 2: Name of class/subclass/project
    # Parameter 3: Typ (class,subclass,project,room, ...)
    # Parameter 4: option delete rsync (unused)
    # Parameter 5: userliste, commaseparated
    my ($login, $name, $type, $rsync,$users) = @_;
    my $from_dir = "";
    my $to_dir = "";
    # home des austeilenden ermitteln
    my ($homedir)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
    if ($type eq "adminclass"){
       $from_dir = "${homedir}/${Language::to_handoutcopy_dir}/".
                   "${Language::to_handoutcopy_string}${name}";
    } elsif ($type eq "subclass"){
       $from_dir = "${homedir}/${Language::to_handoutcopy_dir}/".
                   "${Language::to_handoutcopy_string}${name}";
    } elsif ($type eq "project"){
       # get the longname
       my ($longname) =
       &Sophomorix::SophomorixPgLdap::fetchinfo_from_project($name);
       $from_dir = "${homedir}/${Language::to_handoutcopy_dir}/".
                   "${Language::to_handoutcopy_string}${longname}";
    } elsif ($type eq "current room"){
       $from_dir = "${homedir}/${Language::to_handoutcopy_dir}".
                   "/${Language::to_handoutcopy_string}${Language::current_room}";
    }

    my @userlist=split(/,/,$users);
    print "   From ($type): ${from_dir}\n";
    # check if there could be files found to handout
    my $found=0;
    opendir DIR, $from_dir or die "Cannot open $from_dir: $!";
    foreach my $file (readdir DIR) {
        if ($file eq "." or $file eq ".."){
	    next;
        }
        $found=1;
        print "      handoutcopy: $file\n";
    }
    closedir DIR;

    if ($found==1){
       foreach my $user (@userlist){
           # home des austeilenden ermitteln
           my ($homedir)=
              &Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
           if ($homedir eq ""){
               print "WARNING: User $user does not exist (cannot handout)\n";
	       next;
           } else {
              if ($type eq "current room"){
                   $to_dir = "${homedir}/${Language::handoutcopy_dir}".
                             "/${Language::handoutcopy_string}".
                             "${Language::current_room}";
              } elsif ($type eq "project") {
                   # get the longname
                   my ($longname) =
                   &Sophomorix::SophomorixPgLdap::fetchinfo_from_project($name);
                   $to_dir = "${homedir}/${Language::handoutcopy_dir}".
                             "/${Language::handoutcopy_string}${longname}";
              } else {
                   $to_dir = "${homedir}/${Language::handoutcopy_dir}".
                             "/${Language::handoutcopy_string}${name}";
              }
              print "   To:   ${to_dir}\n";
              system ("cp -a $from_dir/* $to_dir");
              system ("chown -R $user:root $to_dir/*");
              system ("chmod -R 0755 $to_dir/*");
           }
        }
    } else {
       print "   No files found to handout\n";    
    }
}




sub collect {
  # Parameter 1: User that collects data
  # Parameter 2: Name of class/subclass/project
  # Parameter 3: Typ (class,subclass,project,room,current room, ...)
  # Parameter 4: options for rsync
  # Parameter 5: exam(0,1) 
  # Parameter 6: users commaseparated
  # rsync
  # -t Datum belassen
  # -r Rekursiv
  # -o Owner beibehalten, -g 
  # TODO: if name is locked for an exam, exit with message
  my ($login,$name,$type,$rsync,$exam,$users) = @_;
  my $date=&zeit_stempel;
  my ($group_type,$longname)=
      &Sophomorix::SophomorixPgLdap::pg_get_group_type($name);
  if($Conf::log_level>=2){
       print "Collect as:              $login\n";
       print "Collect from type:       $type\n";
       print "Collect from :           $name ($longname)\n";
       print "rsync Options:           $rsync\n";
       print "Exam (boolean):          $exam\n";
       print "Users:                   $users\n";
  }

  # where to get _Task data
  my $tasks_dir = "";

  # create a list of user to collect data from
  my @users=();
  if ($type eq "adminclass" and not defined $users){
      if ($name ne "${DevelConf::teacher}"){
         @users=&Sophomorix::SophomorixPgLdap::fetchstudents_from_adminclass($name);
         $tasks_dir="${DevelConf::tasks_classes}/${name}/";
     } else {
         # nix
         # make collection from teachers possible ???????
     }
  } elsif ($type eq "subclass" and not defined $users){
      # gruppenmitglieder 
      my ($name,$passwd,$gid,$members)=getgrnam($name);
      @users=split(/,/, $members);
      $tasks_dir="${DevelConf::tasks_subclasses}/${name}/";
  } elsif ($type eq "project" and not defined $users){
      @users=&Sophomorix::SophomorixPgLdap::fetchusers_from_project($name);
      $tasks_dir="${DevelConf::tasks_projects}/${name}/";
  } elsif ($type eq "room" and not defined $users){
      @users=&Sophomorix::SophomorixPgLdap::fetchworkstations_from_room($name);
      # no tasks dir
  } elsif ($type eq "current room"){
      @users=split(/,/,$users);
      # no tasks dir
  } elsif ($type eq "project"){
      @users=split(/,/,$users);
      $tasks_dir="${DevelConf::tasks_projects}/${name}/";
  } elsif ($type eq "adminclass"){
      @users=split(/,/,$users);
      $tasks_dir="${DevelConf::tasks_classes}/${name}/";
  } elsif ($type eq "room"){
      @users=split(/,/,$users);
      $tasks_dir="${DevelConf::tasks_rooms}/${name}/";
  }

  # where to save the collected data
  my ($homedir_col)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);
  my $to_dir="";

  if (defined $users and $type eq "current room"){ 
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${Language::current_room}/".
                   "${login}_${date}_${Language::current_room}";
  } elsif (defined $users) {
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${longname}/".
                   "${login}_${date}_${longname}";
  } else {
     if ($exam==1){
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${Language::exam}/".
                    "EXAM_${login}_${date}_${longname}";
     } else {
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${longname}/".
                   "${login}_${date}_${longname}";
     }
  }

  # ???? make more secure
  if ($to_dir =~ /(.*)/) {
      $to_dir=$1;
  }  else {
      die "Bad data in $to_dir";   # Log this somewhere.
  }

  # for exams
  my $log_dir = "${DevelConf::log_pfad_ka}/EXAM_${login}_${date}_${name}";
  # ???? make more secure
  if ($log_dir =~ /(.*)/) {
     $log_dir=$1;
  }  else {
     die "Bad data in $log_dir"; # Log this somewhere.
  }
 
  # collect data from all users
  foreach my $user (@users){
      my ($homedir)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
      my $from_dir="$homedir/${Language::collect_dir}/";

# collect from _einsammeln

#      my $from_dir="";
#      if ($type eq "current room"){
#          $from_dir="$homedir/${Language::collect_dir}/${Language::current_room}/";
#      } elsif ($type eq "room") {
#          $from_dir="$homedir/${Language::collect_dir}/${Language::current_room}/";
#      } elsif ($type eq "project") {
#          $from_dir="$homedir/${Language::collect_dir}/${longname}/";
#      } elsif ($type eq "adminclass") {
#          $from_dir="$homedir/${Language::collect_dir}/${longname}/";
#      } else {
#          $from_dir="$homedir/${Language::collect_dir}/${login}/";
#      }


      # ???? make more secure
      if ($from_dir =~ /(.*)/) {
         $from_dir=$1;
      }  else {
         die "Bad data in $from_dir"; # Log this somewhere.
      }

      # ???? make more secure
      if ($to_dir =~ /(.*)/) {
         $to_dir=$1;
      }  else {
         die "Bad data in $to_dir";   # Log this somewhere.
      }

      &linie();
      print "$user   From: ${from_dir}\n";
      print "          To: ${to_dir}/${user}\n";

      # collect the data
      system("/usr/bin/install -d $to_dir/${user}");  

      if (-e $from_dir and -d $from_dir){
          system("ls $from_dir");
          if ($rsync eq "delete") {
              # sync to user 
              system("/usr/bin/rsync -tor --delete $from_dir ${to_dir}/${user}");
              # exam
              if ($exam==1){
                 system("/usr/bin/install -d $log_dir");  
                 system("/usr/bin/rsync -tr --delete $from_dir ${log_dir}/${user}");
              }
          } elsif ($rsync eq "copy"){
              system("/usr/bin/rsync -tor $from_dir ${to_dir}/${user}");
          } elsif ($rsync eq "move"){
              system("/bin/mv ${from_dir}* ${to_dir}/${user}");
          } else {
              print "unknown Parameter $rsync";
          }
      } else {
	  print "WARNING: $from_dir nonexisting/not a directory\n";
      }
  }
  

  # collect tasks
  if ($type eq "current room"){
      # do nothing
  } elsif ($type eq "room") {
      # do nothing
  }else {
      # ???? make more secure
      if ($tasks_dir =~ /(.*)/) {
         $tasks_dir=$1;
      }  else {
         die "Bad data in $tasks_dir";   # Log this somewhere.
      }
      my $from_dir=${tasks_dir}.${login}."/";
      &linie();
      print "TASKS:\n";
      print "  From: ${from_dir}\n";
      print "  To:   ${to_dir}/${Language::task_dir}\n";

      if (-e $from_dir and -d $from_dir){
          system("ls $from_dir");
          system("/usr/bin/rsync -tor ${from_dir} ${to_dir}/${Language::task_dir}");

          # exam
          if ($exam==1){
            system("/usr/bin/install -d $log_dir");  
            system("/usr/bin/rsync -tr $from_dir ${log_dir}/${Language::task_dir}");
            system("/bin/chown -R root.root ${log_dir}");
          }
      } else {
	  print "WARNING: $from_dir nonexisting/not a directory\n";
      }
      &linie();
  }


  # make collected data readable
#  system("/bin/chown -R $login.${DevelConf::teacher} $dir");
  system("/bin/chown -R $login. $to_dir");

}



###############################################################################
# HTACCESS-TOOLS
###############################################################################

# users
sub fetchhtaccess_from_user {
    my ($user) = @_;
    my $upload=0;
    my $public=0,
    my $result="user-";
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    if ($type eq "teacher"){
        $ht_target=${DevelConf::www_teachers}."/".$user."/.htaccess";
    } elsif ($type eq "student"){
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
    } else {
        return "";
    }
    open(FILE, "<$ht_target");
    while (<FILE>) {
        chomp(); # Returnzeichen abschneiden
        s/\s//g; # Spezialzeichen raus
        if(/^\#public/){
            $public=1;
        }
        if(/^\#upload/){
            $upload=1;
        }
    }
    close(FILE);
    if ($public==1){
        $result=$result."public-";
    } else {
        $result=$result."private-";
    }
    if ($upload==1){
        $result=$result."upload";
    } else {
        $result=$result."noupload";
    }
    return $result;
}

sub user_public_upload {
    my ($user) = @_;
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    my $ht_replace= " -e 's/\@\@username\@\@/${user}/g'".
                    " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="";
    my $ht_target="";

    if ($type eq "teacher"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.teacher_public_upload-template";
        $ht_target=${DevelConf::www_teachers}."/".$user."/.htaccess";
    } elsif ($type eq "student"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.student_public_upload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
    } else {
        # not student, not teacher
        print "   WARNING: $user is not a student/teacher",
              " (cannot user-public-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying  $ht_target (user-public-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;

    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}



sub user_public_noupload {
    my ($user) = @_;
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    my $ht_replace= " -e 's/\@\@username\@\@/${user}/g'".   
       " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="";
    my $ht_target="";

    if ($type ne "student"){
        print "   WARNING: $user is not a student",
              " (cannot user-public-noupload)\n";
        return 0;
    } else {
        $ht_template="${DevelConf::apache_templates}"."/".
                     "htaccess.student_public_noupload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
    }
    
    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying $ht_target (user-public-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}


sub user_private_upload {
    my ($user) = @_;
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    my $ht_replace= " -e 's/\@\@username\@\@/${user}/g'".
                    " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="";
    my $ht_target="";

    if ($type eq "teacher"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.teacher_private_upload-template";
        $ht_target=${DevelConf::www_teachers}."/".$user."/.htaccess";
    } elsif ($type eq "student"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.student_private_upload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
    } else {
        # not student, not teacher
        print "   WARNING: $user is not a student/teacher",
              " (cannot user-private-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying  $ht_target (user-private-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}



sub user_private_noupload {
    my ($user) = @_;
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
        my $ht_replace= " -e 's/\@\@username\@\@/${user}/g'".
                " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="";
    my $ht_target="";

    if ($type ne "student"){
        print "   WARNING: $user is not a student",
              " (cannot user-private-noupload)\n";
        return 0;
    } else {
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.student_private_noupload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying $ht_target (user-private-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}







# groups
sub fetchhtaccess_from_group {
    my ($group) = @_;
    my $upload=0;
    my $public=0,
    my $result="group-";
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);

    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
    } else {
	return "";
    }

    open(FILE, "<$ht_target");
    while (<FILE>) {
        chomp(); # Returnzeichen abschneiden
        s/\s//g; # Spezialzeichen raus
        if(/^\#public/){
            $public=1;
        }
        if(/^\#upload/){
            $upload=1;
        }
    }
    close(FILE);
    if ($public==1){
        $result=$result."public-";
    } else {
        $result=$result."private-";
    }
    if ($upload==1){
        $result=$result."upload";
    } else {
        $result=$result."noupload";
    }
    return $result;
}


sub group_public_upload {
    my ($group) = @_;
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);
    my $ht_replace= " -e 's/\@\@groupname\@\@/${group}/g'".
                    " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.group_public_upload-template";
    my $ht_target="";
    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
    } else {
        # not adminclass, not project
        print "   WARNING: $group is not a adminclass/project",
              " (cannot group-public-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying  $ht_target (group-public-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}



sub group_public_noupload {
    my ($group) = @_;
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);
    my $ht_replace= " -e 's/\@\@groupname\@\@/${group}/g'".   
       " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="${DevelConf::apache_templates}"."/".
                     "htaccess.group_public_noupload-template";
    my $ht_target="";
    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
    } else {
        # not adminclass, not project
        print "   WARNING: $group is not a adminclass/project",
              " (cannot group-public-noupload)\n";
        return 0;
    }
    
    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying $ht_target (group-public-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}


sub group_private_upload {
    my ($group) = @_;
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);
    my $ht_replace= " -e 's/\@\@groupname\@\@/${group}/g'".
                    " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.group_private_upload-template";
    my $ht_target="";
    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
    } else {
        # not adminclass, not project
        print "   WARNING: $group is not a adminclass/project",
              " (cannot group-private-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying  $ht_target (group-private-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}



sub group_private_noupload {
    my ($group) = @_;
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);
    my $ht_replace= " -e 's/\@\@groupname\@\@/${group}/g'".
                " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.group_private_noupload-template";
    my $ht_target="";
    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
    } else {
        # not adminclass, not project
        print "   WARNING: $group is not a adminclass/project",
              " (cannot group-private-noupload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "   modifying $ht_target (group-private-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "   Setting owner/gowner ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid) to:\n     $ht_target\n";
    chown $uid, $gid, $ht_target;
    return 1;
}








################################################################################
# DEBIAN-TOOLS
################################################################################

sub get_debconf_value {
    my ($package,$entry,$show)=@_;
    # show=1, show messages
    if (not defined $show){
	$show=1;
    }
    my $result=`echo get $package/$entry | debconf-communicate`;
    chomp($result);
    $_=$result;
    if ($show==1){
       print "$result\n\n";
    }
    if (m/doesn.?t exist/){
	return 0;
    } else {
       my ($value,$ret)=split(/ /, $result);
       if ($show==1){
          print "$package/$entry: $ret \n";
       }
       return $ret;
    }
}




################################################################################
# WEBMIN
################################################################################

# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
