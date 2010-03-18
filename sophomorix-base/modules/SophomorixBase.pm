#!/usr/bin/perl -w
# $Id$
# This perl module is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@gmx.de


# aufspalten in:  
#    SophomorixBase
#    SophomorixQuota
#    SophomorixSamba
#    SophomorixAPI

package Sophomorix::SophomorixBase;
require Exporter;
use File::Basename;
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
              fetch_repairhome
              get_alle_verzeichnis_rechte
              get_v_rechte
              setup_verzeichnis
              backup_dir_to_attic
              make_some_files_root_only
              chmod_chown_dir
              fetch_smb_conf
              show_smb_conf_umask
              permissions_from_umask
              remove_line_from_file
              get_old_info 
              save_tausch_klasse
              extra_kurs_schueler
              lehrer_ordnen
              zeit_stempel
              recode_to_ascii
              recode_to_ascii_underscore
              do_falls_nicht_testen
              nscd_start
              nscd_stop
              nscd_flush_cache
              check_options
              check_datei_exit
              check_config_template
              check_datei_touch
              check_verzeichnis_mkdir
              get_user_history
              get_group_list
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
              cyrus_connect
              imap_connect
              imap_disconnect
              imap_show_mailbox_info
              imap_create_mailbox
              imap_rename_mailbox
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
              make_dir_locked
              repair_repairhome
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
              get_debian_version
              get_lsb_release_codename
              deb_system
              basedn_from_domainname
              unlink_immutable_tree
              move_immutable_tree
              set_immutable_bit
              fetch_immutable_bit
              print_forward
              read_cyrus_redirect
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

=item I<get_homedir_permissions()>

Reads all permissions below homedirs

=cut
sub fetch_repairhome {
   # files repairhome.$type to read
   my @typelist = ("administrator","teacher","student",
                   "examaccount","attic","domcomp");

   # data structure: hash of arrays
   my @administrator=();     
   my @teacher=();     
   my @student=();     
   my @workstation=();
   my @attic=();
   my @domcomp=();
   %all_repairhome=();
   $all_repairhome{"administrator"}=\@administrator;
   $all_repairhome{"teacher"}=\@teacher;
   $all_repairhome{"student"}=\@student;
   $all_repairhome{"examaccount"}=\@workstation;
   $all_repairhome{"attic"}=\@attic;
   $all_repairhome{"domcomp"}=\@domcomp;

   foreach my $type (@typelist){

      my $file="$DevelConf::devel_pfad/repairhome"."."."$type";
      if (not -e $file){
         print "\nERROR: Could not read $file\n\n";
         exit;
      }
      open(REPAIRHOME, "<$file");
      if($Conf::log_level>=2){
          &titel("Reading $file");
      }
      while (<REPAIRHOME>) {
          chomp(); # Returnzeichen abschneiden
          s/\s//g; # Spezialzeichen raus
          if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
          if(/^\#/){next;} # Bei Kommentarzeichen aussteigen

          if ($type eq "administrator"){
	      push @administrator, $_;
          }
          if ($type eq "teacher"){
	      push @teacher, $_;
          }
          if ($type eq "student"){
	      push @student, $_;
          }
          if ($type eq "examaccount"){
	      push @workstation, $_;
          }
          if ($type eq "attic"){
	      push @attic, $_;
          }
          if ($type eq "domcomp"){
	      push @domcomp, $_;
          }
      }
      close(REPAIRHOME);
   }
   # return a reference
   return \%all_repairhome;
}



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
   my @files_to_read=("$DevelConf::devel_pfad/repair.directories",
                      "$DevelConf::devel_pfad/repairhome.teacher",
                     );
   foreach my $file (@files_to_read){
       open(REPAIR, "<$file");
       while (<REPAIR>) {
           chomp(); # Returnzeichen abschneiden
           s/\s//g; # Spezialzeichen raus
           if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
           if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
           ($verzeichnis,$owner,$gowner,$permissions)=split(/::/);
           $alle_verzeichnis_rechte{$verzeichnis}=$_;
       }
       close(REPAIR);
   }
   
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

      # user override
      if (defined $user) {
          # owner ersetzen, falls $schueler, $lehrer
          $owner=~s/\$schueler/$user/;
          $owner=~s/\$lehrer/$user/;
          $owner=~s/\$workstation/$user/;
          $owner=~s/\$user/$user/;
      }

      # group override
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



sub backup_dir_to_attic {
    # backup an zip dir to attic
    # 1: Directory to be backuped
    # 2: /home/attic/2
    # 3: /home/attic/dir/3        (prefix: date suggested)
    # 4: /home/attic/dir/date_name/4
    # 5: bzip2 --> compress /home/attic/dir/date_3
    # 6: backup(1) or no backup(0)
    #
    # multiple backup_dir_to_attic can be run with same value for 1-3
    # 4 shows subdir in 1-3; 5=bzip2 compresses all
    my ($dir,$attic_dir,$attic_name,
        $attic_short,$compress,$backup)=@_;
    if (not defined $compress){
	$compress="";
    }

    if ($backup==0){
       # no backup
       &unlink_immutable_tree("$dir",1);
       #my $command="rm -rf $dir";
       #print "$command\n";
       #system("$command");
    } else {
       # backup
       my $attic=${DevelConf::attic}."/"."$attic_dir";
       if (not -e "$attic"){
           system("mkdir $attic");
       }
       my $attic_subdir=$attic."/".$attic_name;
       if (not -e "$attic_subdir"){
           system("mkdir $attic_subdir");
       }
       my $mv_target=$attic_subdir."/".$attic_short;
       if (not -e "$mv_target"){
           system("mkdir $mv_target");
       }

       print "Backing up $dir to \n",
             " $mv_target\n";
       &move_immutable_tree("$dir","$mv_target");
       #my $command="mv $dir $mv_target";
       #print "$command\n";
       #system("$command");
       my $bz2_file= $attic_name.".tar.bz2";
       my $bz2_dir = $attic_name;
       if ($compress eq "bzip2"){
           my $command="cd $attic; tar -cjf  $bz2_file $bz2_dir ".
                    "&& rm -rf $bz2_dir; chmod 600 $bz2_file;";
           print "$command\n";
           system("$command");
       }
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
            print "WARNING: File $root_file nonexisting, ",
                  "cannot make it root only.\n";
        }
    }
}



sub chmod_chown_dir {
    my ($path,$dir_perm,$file_perm,$owner,$gowner) = @_;
    # empty option: do not set  
    my $command="";

    # chmod dirs
    if ($dir_perm ne ""){
        $command="find $path -type d -print0 | xargs --no-run-if-empty -0 chmod $dir_perm";
        print "$command\n";
        system("$command");
    }

    # chmod files
    if ($file_perm ne ""){
        $command="find $path -type f -print0 | xargs --no-run-if-empty -0 chmod $file_perm";
        print "$command\n";
        system("$command");
    }

    # owner.gowner
    if ($owner ne "" or $gowner ne ""){
        $command="chown -R ${owner}.${gowner} $path";
        print "$command\n";
        system("$command");
    }
}



sub fetch_smb_conf {
    %smb_conf=();
    my $file="/etc/samba/smb.conf";
    open(SMBCONF,"<$file");
    my $current_share="";
    while (<SMBCONF>){
        chomp(); # Returnzeichen abschneiden
        s/\s//g; # Spezialzeichen raus
        if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
        if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
        if(/^\;/){next;} # Bei Kommentarzeichen aussteigen
        #print $_,"\n";
        if (/^\[([A-Za-z_-]+)\]/){
            #print "Share $1\n";
            $current_share=$1
	} else {
	   my ($option,$value)=split(/=/);
           #print "   $current_share  -> $option -> $value \n";
           $smb_conf{$current_share}{$option}="$value";
        }
    }
    close(SMBCONF);
    return \%smb_conf;
}

sub show_smb_conf_umask {
    my ($share) = @_;
    my $path;
    my $create_dir;
    my $create_file;
    my $owner;
    my $gowner;
    my ($umask,$umask_dir,$umask_file)=&permissions_from_umask();

    if (exists $smb_conf{$share}{"path"}) {
        $path=$smb_conf{$share}{"path"};
    } else {
        $path="";
    }

    if (exists $smb_conf{$share}{"directorymask"}) {
        $create_dir=$smb_conf{$share}{"directorymask"};
    } else {
        # use umask
	print "using umask $umask for dir: $umask_dir\n";
        $create_dir=$umask_dir;
    }

    if (exists $smb_conf{$share}{"createmask"}) {
        $create_file=$smb_conf{$share}{"createmask"};
    } else {
        # use umask
	print "using umask $umask for file: $umask_file\n";
        $create_file=$umask_file;
    }

    if (exists $smb_conf{$share}{"owner"}) {
        $owner=$smb_conf{$share}{"owner"};
    } else {
        $owner="";
    }

    if (exists $smb_conf{$share}{"forcegroup"}) {
        $gowner=$smb_conf{$share}{"forcegroup"};
    } else {
        $gowner="";
    }

    return ($path,$create_dir,$create_file,$owner,$gowner);
} 

sub permissions_from_umask {
    # fetching umask
    my ($umask) = umask;
    # convert from actal number to string
    $umask=sprintf "%04o",$umask;
   
    # input
    my @digits_umask=split(//,$umask);
    my @digits_dir=(0,7,7,7);
    my @digits_file=(0,6,6,6);

    # result    
    my @umask_dir=();
    my @umask_file=();

    for (my $count=0;$count<=3;$count++)  {
        my $digit_dir=$digits_dir[$count]-$digits_umask[$count];
        my $digit_file=$digits_file[$count]-$digits_umask[$count];
        if ($digit_file < 0){
            $digit_file=0;
        }
	push @umask_dir, $digit_dir;
	push @umask_file, $digit_file;
    }

    my $umask_dir=join("",@umask_dir);
    my $umask_file=join("",@umask_file);
    return ($umask,$umask_dir,$umask_file);    
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
   my %new_id_old_id=();
   # index: system identifier
   my %old_teach_in_sys=();
   # index: administration software identifier
   my %old_teach_in_admin=();
   my ($admin_class, $gecos,$login, $pass,$birth)=();
   my ($name,$surname)=();
   my ($passwd_login,$spass,$id,$gid,$passwd_gecos,$home,$shell)=();
   my ($gname,$gpass,$group_gid);
   my ($identifier_sys,$identifier_admin);
   print "Teach-in: $teach_in\n";
   open(TEACHINDATEN,"$teach_in") || die "Fehler: $!";
   &titel("Extracting data from old teach-in.txt ...");
   while(<TEACHINDATEN>){
      chomp();
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($identifier_sys,$identifier_admin)=split(/:::/);
      # create hash with index admin
      if (exists $old_teach_in_admin{$identifier_admin}){ 
	   print "   ERROR: Identifier  $identifier_admin exists ",
                 "multiple times in old teach-in.txt.\n";
      } else {
         $old_teach_in_admin{$identifier_admin}="$identifier_sys";
      }
      # create hash with index sys
      if (exists $old_teach_in_sys{$identifier_sys}){ 
	   print "   ERROR: Identifier  $identifier_sys exists ",
                 "multiple times in old teach-in.txt.\n";
      } else {
         $old_teach_in_sys{$identifier_sys}="$identifier_admin";
      }
      # create hash with new_id old_id
      if (exists $new_id_old_id{$identifier_admin}){ 
	   print "   ERROR: Identifier  $identifier_admin exists ",
                 "multiple times in old teach-in.txt.\n";
      } else {
         $new_id_old_id{$identifier_admin}="$identifier_sys";
      }

   }
   close(TEACHINDATEN);

   #print "\nOld_teach_in_admin \n";
   #  while (($key,$value) = each %old_teach_in_admin){
   #      printf "%-39s %39s\n","$key","$value";
   #   }
   #print "\nOld_teach_in_sys \n";
   #  while (($key,$value) = each %old_teach_in_sys){
   #      printf "%-39s %39s\n","$key","$value";
   #   }
   #print "\nnew_id_old_id \n";
   # my $count_up=0; 
   # while (($key,$value) = each %new_id_old_id){
   #	$count_up++;
   #      printf "%-39s %39s\n","$count_up $key","$value";
   #   }

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



   # first run through user_db
   # save system identifier an their login in the system
   # for later use
   my $sysid_login=();
   open(PROTOCOL, "<$protocol") || die "Fehler: $!";
   while(<PROTOCOL>){
       chomp($_);
      my ($sys_admin_class, $sys_gecos,$sys_login, 
          $sys_pass,$sys_birth)=split(/;/);
      my ($sys_name,$sys_surname)=split(/\ /,$sys_gecos); 
        $sys_identifier="$sys_surname".";"."$sys_name".";"."$sys_birth";

       $sysid_login{$sys_identifier}="$sys_login";

 
   }
   close(PROTOCOL);

   # second run through user_db
   # creating identifier -> ... hashes
   open(PROTOCOL, "<$protocol") || die "Fehler: $!";
   &titel("Extracting data from old user_db ...");
   while(<PROTOCOL>){
       chomp($_);
       ($admin_class, $gecos,$login, $pass,$birth)=split(/;/);
       ($name,$surname)=split(/\ /,$gecos); 
        $identifier="$surname".";"."$name".";"."$birth";

       # if identifier exists in teach in as administartion identifier
       # then it has different sys identifier and login must be adjusted
       if (exists $old_teach_in_admin{$identifier}){
          # adjusting identifier according to teach-in.txt
	  print "teach-in entry found:\n   $identifier is ",
                "$old_teach_in_admin{$identifier} in the old system\n";
          # adjusting $login with the identifier in the system
          $login=$sysid_login{$old_teach_in_admin{$identifier}};
          print "   save this in old_id_login: $identifier   $login \n";
       }

       # if identifier exists in teach-in as system identifier
       # then it has a changed administration identifier and is not needed
     # It is needed to find the new password

     #  if (exists $old_teach_in_sys{$identifier}){
     #      next;
     #  }

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

   #print "\nold_id_login \n";
   # while (($key,$value) = each %old_id_login){
   #      printf "%-39s %39s\n","$key","$value";
   # }


   # return references to the hashes
   return(\%old_id_login,
          \%old_id_password,
          \%old_id_id,
          \%old_group_gid, 
          \%new_id_old_id 
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
   my $dirpath="$homedir"."/${Language::user_attic}/"."${Language::share_string}".
               "$dirname"."/";
   my $tausch_klasse_path = "";
   if ($klasse eq ${DevelConf::teacher}) {
     $tausch_klasse_path = "${DevelConf::share_teacher}";
   } else {
     $tausch_klasse_path = "${DevelConf::share_classes}/"."$klasse";
   }
   # abs. Pfade der zu movenden Verzeichnisse im Tauschverzeichnis 
   # in eine Liste schreiben
   print "Look in class share: $tausch_klasse_path\n";
   print "Backup to here: \n   $dirpath\n";

   if (not -e "$tausch_klasse_path"){
       # do nothing
   } else {
       opendir KTAUSCH, $tausch_klasse_path or return;
       foreach my $datei (readdir KTAUSCH){
          if ($datei eq "."){next};
          if ($datei eq ".."){next};
          my $path=("$tausch_klasse_path"."/"."$datei");
          my @statliste=lstat($path);
          my $owner = getpwuid $statliste[4];
          # if file/dir is owned by user
          # Todo: use find to find files
          if ($owner eq "$login") {
             # move it
             if (not -e "$dirpath") {
                 &do_falls_nicht_testen(
                 "install -d -o$login -g${DevelConf::teacher} $dirpath"
                 );
             };
             print "     * Move: $datei (owner: $owner)\n";
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
    my ($class,$type) = @_;
    if (not defined $type){
	$type="";
    }
    if ($type eq "examaccount"){
      # nothing
    } elsif ($class eq ${DevelConf::teacher}){
      &setup_verzeichnis("\$share_teacher",
                    "${DevelConf::share_teacher}");
      if ($DevelConf::create_www==1){
         &setup_verzeichnis("\$www_teachers",
                       "${DevelConf::www_teachers}");
      }
    } else {
      my $klassen_homes="${DevelConf::homedir_pupil}/$class";
      my $klassen_tausch="${DevelConf::share_classes}/$class";
      my $klassen_aufgaben="${DevelConf::tasks_classes}/$class";
      my $klassen_www="${DevelConf::www_classes}/$class";

      my $ht_access_target=$klassen_www."/.htaccess";
      &setup_verzeichnis("\$homedir_pupil/\$klassen",
                    "$klassen_homes");
      &setup_verzeichnis("\$share_classes/\$klassen",
                    "$klassen_tausch",
                    undef,
                    "$class");
      &setup_verzeichnis("\$tasks_classes/\$klassen",
                    "$klassen_aufgaben");

      if ($DevelConf::create_www==1){
          &setup_verzeichnis("\$www_classes/\$klassen",
                            "$klassen_www");
          # create .htaccess file if nonexisting
          if (not -e $ht_access_target){
              &group_private_noupload($class);
          }
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
                       "$project_tausch",
                       "",
                       $project);
    &setup_verzeichnis("\$tasks_projects/\$projects",
                       "$project_aufgaben");
    if ($DevelConf::create_www==1){
        &setup_verzeichnis("\$www_projects/\$projects",
                           "$project_www");
        # create .htaccess file if nonexisting
        if (not -e $ht_access_target){
            &group_private_noupload($project);
        }
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

    if ($DevelConf::testen==0) {
        # create all dirs in $HOME for all users
        &repair_repairhome($login);
    }

    if ($class eq ${DevelConf::teacher}){
        ####################
        # teacher
        ####################
        $home = "${DevelConf::homedir_teacher}/$login";
        $www_home = "${DevelConf::homedir_teacher}/$login/www";
        $share_class = "${DevelConf::share_teacher}";

        if ($DevelConf::create_www==1){
           $htaccess_template="${DevelConf::apache_templates}"."/".
                           "htaccess.teacher.private_html-template";
           $htaccess_target=$home."/private_html/.htaccess";
           $htaccess_sed_command=
               "sed $htaccess_replace $htaccess_template > $htaccess_target";

           # create dirs outside $HOME
           &setup_verzeichnis("\$www_teachers/\$lehrer",
                              "${DevelConf::www_teachers}/$login",
                              "$login");
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
           &user_private_upload($login);
        }

        &create_share_link($login,$class,$class,"teacher");
        &create_share_directory($login,$class,$class,"teacher");
        &create_school_link($login);
    } elsif ($type eq "adminclass") { 
        ####################
        # student
        ####################
        $home_class = "${DevelConf::homedir_pupil}/$class";
        $home = "${DevelConf::homedir_pupil}/$class/$login";
        $www_home = "${DevelConf::homedir_pupil}/$class/$login/www";
        $share_class = "${DevelConf::share_classes}/$class";

        if ($DevelConf::create_www==1) {
           $htaccess_template="${DevelConf::apache_templates}"."/".
                              "htaccess.student.private_html-template";
           $htaccess_target=$home."/private_html/.htaccess";
           $htaccess_sed_command=
              "sed $htaccess_replace $htaccess_template > $htaccess_target";
           # create dirs outside $HOME
           # what is this for ?
           #system("chown -R $login:${DevelConf::teacher} $home");
           &setup_verzeichnis("\$www_students/\$schueler",
                              "${DevelConf::www_students}/$login",
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
        }
        &create_share_link($login,$class,$class,"adminclass");
        &create_share_directory($login,$class,$class,"adminclass");
        &create_school_link($login);
    } elsif ($type eq "room"){
        ####################
        # workstation
        ####################
        if ($DevelConf::testen==0) {
           $home_ws = "${DevelConf::homedir_ws}/$class";
           $home = "${DevelConf::homedir_ws}/$class/$login";
           # create dirs outside $HOME
           # Wozu ist das gut ???
           #system("chown -R $login:${DevelConf::teacher} $home");
         }
    } else {
        print "\nERROR: Could not determine type of $class\n\n";
    }
}


sub make_dir_locked {
    my ($dir) = @_;
    my $file=".locked";
    if (not -e $dir){
        print "Cannot create .locked in $dir (nonexisting)\n";
    } else {
        my $path=$dir."/".$file;
        if (not -e $path){
            if($Conf::log_level>=2){
                print "        creating $path\n";
            }        
            system("touch $path");
            system("chown administrator.administrators $path");
            system("chmod 0600 $path");
        } 
    }
}



sub repair_repairhome {
    my ($user) = @_;
    my ($home,$type)=
       &Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    my @groups=&Sophomorix::SophomorixPgLdap::pg_get_group_list($user);
    if ($home eq "" or $type eq ""){
        print "WARNING: Could not find data for user $user. ".
              "NOT repairing home!\n";
	return;
    }
    if ($type eq "none"){
        print "NOT repairing dirs under \$HOME. User is of type '$type'\n";
        return;
    }
    # use permissions according to type
    my @permissions=@{$all_repairhome{$type}};

    if($Conf::log_level>=2){
        print "Repairing \$HOME of user $user (type: $type)\n";
    }
    foreach my $line (@permissions){
        my ($path,$owner,$gowner,$octal,$immutable)=split(/::/,$line);
        if($Conf::log_level>=2){
            print "    * $line\n";
        }
        # put octal in a array
        my @octal=split(/\//,$octal);

        # replacing static aviables in owner
        $owner=~s/\$user/$user/;     
 
        # replacing static variables in gowner
        $gowner=~s/\$teachers/${DevelConf::teacher}/;     
        $gowner=~s/\$apache_group/${DevelConf::apache_group}/;     

        # replacing static variables in the path
        # develconv

        # lang
        $path=~s/\$current_room/$Language::current_room/;     
        $path=~s/\$exam/$Language::exam/;     
        $path=~s/\$collect_dir/$Language::collect_dir/;     

        $path=~s/\$collected_dir/$Language::collected_dir/;     
        $path=~s/\$collected_string/$Language::collected_string/;     

        $path=~s/\$task_dir/$Language::task_dir/;     
        $path=~s/\$task_string/$Language::task_string/;     

        $path=~s/\$handout_dir/$Language::handout_dir/;     
        $path=~s/\$handout_string/$Language::handout_string/;     

        $path=~s/\$handout_dir/$Language::handout_dir/;     
        $path=~s/\$handout_string/$Language::handout_string/;     

        $path=~s/\$handoutcopy_dir/$Language::handoutcopy_dir/;     
        $path=~s/\$handoutcopy_string/$Language::handoutcopy_string/;     

        $path=~s/\$to_handoutcopy_dir/$Language::to_handoutcopy_dir/;     
        $path=~s/\$to_handoutcopy_string/$Language::to_handoutcopy_string/;     

        $path=~s/\$share_dir/$Language::share_dir/;     
        $path=~s/\$share_string/$Language::share_string/;     
        $path=~s/\$school/$Language::school/;     
        $path=~s/\$user_attic/$Language::user_attic/;
     
	$path=$home."/".$path;
       
        # save the static modied path
        my $path_static_modified=$path;

        # looking for dynamic $mygroups
        if ($path_static_modified=~m/\$mygroups/){
	    # variable $mygroups detected
            foreach my $group (@groups){
                my $path_to_change=$path_static_modified;
                if ($group eq ${DevelConf::teacher}){
                    # teachers -> Lehrer
   	            $path_to_change=~s/\$mygroups/${Language::teacher}/g;
                } else {
  	            $path_to_change=~s/\$mygroups/$group/g;
		}
                &repair_directory_no_var($path_to_change,
                                         $owner,$gowner,
                                         $immutable,@octal);
                }
        } else {
            # no variable detected
            &repair_directory_no_var($path_static_modified,
                                     $owner,$gowner,
                                     $immutable,@octal);
        }
    }
} 


# following sub is not exported, user only herein
sub repair_directory_no_var {
    my ($path,$owner,$gowner,$immutable,@octal) = @_;

    # remember and remove immutable bit on parent dir
    my $parent_dir = dirname $path;
    my $immutable_bit=&fetch_immutable_bit($parent_dir);
    &set_immutable_bit($parent_dir,0);

    # create if nonexisting
    if (not -e "$path"){
        system("mkdir $path");
    }  

    if (-e "$path"){
        # remove immutable bit
	&set_immutable_bit($path,0);

        # owner
        my $command_1="chown ${owner}:${gowner} $path";
        if($Conf::log_level>=2){
            print "        $command_1\n";
        }
        system("$command_1");

        # permissions
        if ($#octal>0){
            # more than one permission given
            # Dateirechte des Verzeichnises ermitteln
            my ($a,$b,$mode) = stat(${path});
            #print "Mode ist $mode\n";
            # Umwandeln in übliche Schreibweise
            $mode &=07777;
            $mode=sprintf "%04o",$mode;

            # Sind die Verzeichnisrechte OK
	    foreach my $perm (@octal){
               if ( $mode==$perm ) {
                   if($Conf::log_level>=2){
                       print "        Mode $mode is OK. Nothing to do!\n";
                   }
                   return;
               } else {
                   if($Conf::log_level>=2){
                       print "        Mode must be set to $octal[0]!\n";
                   }
                   if($Conf::log_level>=2){
                       print "        chmod $octal[0] $path\n";
                   }
                   chmod oct($octal[0]), $path;
               } 
           }
        } else {
            if($Conf::log_level>=2){
                print "        chmod $octal[0] $path\n";
            }
            chmod oct($octal[0]), $path;
        }

        # set immutable bit if necesary
        if (defined $immutable){
           if ($immutable eq "immutable"){
               if($Conf::log_level>=2){
                   print "        setting immutable bit to $path\n";
               }
	       &set_immutable_bit($path,1);
           }
        }
    }

    # restore stored value for immutable bit of parent
    &set_immutable_bit($parent_dir,$immutable_bit);
    return;
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

   my ($old_uid,$new_uid) = @_;
   if (not defined $old_uid){
       $old_uid="";
   }
   if (not defined $new_uid){
       $new_uid="";
   }


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

     if ($typ eq "lehrer" or
         $typ eq "Lehrer" or
         $typ eq "teacher" or
         $typ eq "Teacher" or
         $typ eq "teachers" or
         $typ eq "Teachers"
         ){
         $typ=$Conf::teacher_group_name;
     }

     if(not defined $wunsch_login){
        # go to next user when final ; is missing
        print LEHRERTMP ("$_\n");
        # next teacher
        next;
     } else {
        # downcase loginnames
          $wunsch_login=~tr/A-Z/a-z/;

     }

     # replacing wunschlogin if options are given
     if ($old_uid ne "" and $new_uid ne ""){
         if ($wunsch_login eq $old_uid){
             $wunsch_login=$new_uid;
         }
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

sub recode_to_ascii_underscore {
    my ($string) = @_;
    $string=~s/ /_/g;
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




sub nscd_start {
    # start nscd
    if (-e $DevelConf::nscd_script){
        # fix: add /sbin to $PATH, because
        # sophomorix-teacher runs with different path
        system("OLDPATH=\$PATH;PATH=\$PATH:/sbin; $DevelConf::nscd_start; PATH=\$OLDPATH");
    }
    #system("/etc/init.d/nscd status ");
}



sub nscd_stop {
    # stop nscd
    if (-e $DevelConf::nscd_script){
        # fix: add /sbin to $PATH, because
        # sophomorix-teacher runs with different path
        system("OLDPATH=\$PATH;PATH=\$PATH:/sbin; $DevelConf::nscd_stop; PATH=\$OLDPATH");
    }
    #system("/etc/init.d/nscd status ");
}

sub nscd_flush_cache {
    # flush_cache tut nur bei laufendem nscd
    if (-e "/usr/sbin/nscd"){
        print "Flushing nscd cache\n";
	system("/usr/sbin/nscd -i passwd -i group -i hosts");
    } else {
        print "WARNING: couldnt flush nscd cache\n";
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
                '2','3','4','5','6','7','8','9',
                );
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
       # remember and remove immutable bit on parent dir
       my $parent_dir = $home."/${Language::share_dir}";
       my $immutable_bit=&fetch_immutable_bit($parent_dir);
       &set_immutable_bit($parent_dir,0);

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
       &set_immutable_bit($parent_dir,$immutable_bit);

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
         and $type ne "examaccount"){
        print "   WARNING: Cannot reset account $user \n";
        print "            Not a student, teacher or workstation\n";
    } else {
        # do some work
        my (@groups) = 
           &Sophomorix::SophomorixPgLdap::pg_get_group_list($user);
#        if (-e $homedir){
            print "   Removing contents of $homedir\n";
            #system("rm -rf ${homedir}/*");
            &unlink_immutable_tree("${homedir}/*"); 
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
#        } else {
#            print "Directory $homedir does not exist\n";
#        }
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
       # save immutable bit on share_dir and unset it
       my $immutable_share_dir=$homedir."/${Language::share_dir}";
       my $immutable_share_bit=&fetch_immutable_bit($immutable_share_dir);
       &set_immutable_bit($immutable_share_dir,0);

       # save immutable bit on task_dir and unset it
       my $immutable_task_dir=$homedir."/${Language::task_dir}";
       my $immutable_task_bit=&fetch_immutable_bit($immutable_task_dir);
       &set_immutable_bit($immutable_task_dir,0);

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
           $link_target="${DevelConf::share_classes}/${share_name}";
           $link_target_tasks="${DevelConf::tasks_classes}/${share_name}";
       }elsif ($type eq "teacher"){
           # teacher
           $link_target="${DevelConf::share_teacher}";
           $link_target_tasks="${DevelConf::tasks_teachers}";
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
       # restore immutable bit
       &set_immutable_bit($immutable_share_dir,$immutable_share_bit);
       &set_immutable_bit($immutable_task_dir,$immutable_task_bit);
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

    # new 
    # create all dirs in $HOME for all users
    &repair_repairhome($login);

    return;

    my ($homedir,$account_type)=
       &Sophomorix::SophomorixPgLdap::fetchdata_from_account($login);

    if ($homedir ne ""){
        # create dirs in handout and collect
        if ($account_type eq "teacher"){
            ##############################
            # teacher
            ##############################

            # handout_parent
            my $handout_parent=$homedir."/".${Language::handout_dir};
            my $immutable_bit_handout_parent=
                &fetch_immutable_bit($handout_parent);
            &set_immutable_bit($handout_parent,0);

            my $handout_dir=$homedir."/".
                ${Language::handout_dir}."/".
                ${Language::handout_string}.$share_long_name;
            if (not -e $handout_dir){
                if($Conf::log_level>=2){
                    print "   Adding directory ${handout_dir}\n"; 
	        }
            }
            system("mkdir $handout_dir");
            system("chown $login:root $handout_dir");
            # restore immutable bit
            &set_immutable_bit($handout_parent,
                               $immutable_bit_handout_parent);


            # to_handoutcopy_parent
            my $to_handoutcopy_parent=$homedir."/".${Language::to_handoutcopy_dir};
            my $immutable_bit_to_handoutcopy_parent=
                &fetch_immutable_bit($to_handoutcopy_parent);
            &set_immutable_bit($to_handoutcopy_parent,0);

            my $to_handoutcopy_dir=$homedir."/".
                ${Language::to_handoutcopy_dir}."/".
                ${Language::to_handoutcopy_string}.$share_long_name;
            if (not -e $to_handoutcopy_dir){
                if($Conf::log_level>=2){
                    print "   Adding directory ${to_handoutcopy_dir}\n"; 
	        }
            }
            system("mkdir $to_handoutcopy_dir");
            system("chown $login:root $to_handoutcopy_dir");
            # restore immutable bit
            &set_immutable_bit($to_handoutcopy_parent,
                               $immutable_bit_handoutcopy_parent);


            # collected_dir
            my $collected_parent=$homedir."/".${Language::collected_dir};
            my $immutable_bit_collected_parent=
               &fetch_immutable_bit($collected_parent);
            &set_immutable_bit($collected_parent,0);

            my $collected_dir=$homedir."/".
                ${Language::collected_dir}."/".
                ${Language::collected_string}.$share_long_name;
            if (not -e $collected_dir){
                if($Conf::log_level>=2){
                    print "   Adding directory ${collected_dir}\n"; 
	        }
            }
            system("mkdir $collected_dir");
            system("chown $login:root $collected_dir");
            # restore immutable bit
            &set_immutable_bit($collected_parent,$immutable_bit_collected_parent);
        }
        ##############################
        # all users
        ##############################
        my $handoutcopy_parent=$homedir."/".${Language::handoutcopy_dir};
        my $immutable_bit_handoutcopy_parent=
            &fetch_immutable_bit($handoutcopy_parent);
        &set_immutable_bit($handoutcopy_parent,0);

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
        # restore immutable bit
        &set_immutable_bit($handoutcopy_parent,$immutable_bit_handoutcopy_parent);
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
        my $attic=$homedir."/".${Language::user_attic};
        # remove dirs in tasks and collect
        if ($account_type eq "teacher"){
            ##############################
            # teacher only
            ##############################
            if($Conf::log_level>=2){
                 print "   Account type is teacher.\n";
            }
            # bereitstellen
            my $handout_dir=$homedir."/".
               ${Language::handout_dir}."/".
               ${Language::handout_string}.$share_long_name;
            if (-e $handout_dir){
                if($Conf::log_level>=2){
                    print "   Removing $handout_dir if empty.\n";
                }

                system("rsync -a $handout_dir $attic");
                if ($handout_dir=~/^\/home\//){
                    #system("rm -rf $handout_dir");
                    &unlink_immutable_tree($handout_dir); 
	        }
                system("rmdir --ignore-fail-on-non-empty $attic/${Language::handout_string}$share_long_name");
                #system("rmdir $handout_dir");
            }
            # austeilen
            my $to_handoutcopy_dir=$homedir."/".
               ${Language::to_handoutcopy_dir}."/".
               ${Language::to_handoutcopy_string}.$share_long_name;
            if (-e $to_handoutcopy_dir){
                if($Conf::log_level>=2){
                    print "   Removing $to_handoutcopy_dir if empty.\n";
                }
                system("rsync -a $to_handoutcopy_dir $attic");
                if ($to_handoutcopy_dir=~/^\/home\//){
                    #system("rm -rf $to_handoutcopy_dir");
                    &unlink_immutable_tree($to_handoutcopy_dir); 
	        }
                system("rmdir --ignore-fail-on-non-empty $attic/${Language::to_handoutcopy_string}$share_long_name");
                #system("rmdir $to_handoutcopy_dir");
            }
            # eingesammelt
            my $collected_dir=$homedir."/".
               ${Language::collected_dir}."/".
               ${Language::collected_string}.$share_long_name;
            if (-e $collected_dir){
                if($Conf::log_level>=2){
                    print "   Removing $collected_dir if empty.\n";
                }
                system("rsync -a $collected_dir $attic");
                if ($collected_dir=~/^\/home\//){
                    #system("rm -rf $collected_dir");
                    &unlink_immutable_tree($collected_dir); 
	        }
                system("rmdir --ignore-fail-on-non-empty $attic/${Language::collected_string}$share_long_name");
                #system("rmdir $collected_dir");
            }
        }
        ##############################
        # all users
        ##############################
        # austeilen
        my $handoutcopy_dir=$homedir."/".
           ${Language::handoutcopy_dir}."/".
           ${Language::handoutcopy_string}.$share_long_name;
        if (-e $handoutcopy_dir){
            if($Conf::log_level>=2){
                print "   Removing $handoutcopy_dir if empty.\n";
            }
            system("rsync -a $handoutcopy_dir $attic");
            if ($handoutcopy_dir=~/^\/home\//){
                #system("rm -rf $handoutcopy_dir");
                &unlink_immutable_tree($handoutcopy_dir); 
	    }
            system("rmdir --ignore-fail-on-non-empty $attic/${Language::handoutcopy_string}$share_long_name");
            #system("rmdir $handoutcopy_dir");
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

sub unlock_sophomorix{
    &titel("Removing lock in $DevelConf::lock_file");
    my $timestamp=&zeit_stempel();
    my $unlock_dir=$DevelConf::lock_logdir."/".$timestamp."_unlock";
    # make sure logdir exists
    if (not -e "$DevelConf::lock_logdir"){
        system("mkdir $DevelConf::lock_logdir");
    }

    if (-e $DevelConf::lock_file){
        # create timestamped dir
        if (not -e "$unlock_dir"){
            system("mkdir $unlock_dir");
        }
        
        # save sophomorix.lock
        system("mv $DevelConf::lock_file $unlock_dir");

        # saving last lines of command.log
        $command="tail -n 100  ${DevelConf::log_command} ".
	         "> ${unlock_dir}/command.log.tail";
        if($Conf::log_level>=3){
   	    print "$command\n";
        }
	system("$command");

        print "Created log data in ${unlock_dir}\n";
    } else {
        &titel("Lock $DevelConf::lock_file did not exist");
    }
}


sub lock_sophomorix {
    my ($type,$pid,@arguments) = @_;
    # $type: lock (lock when not existing)
    # $type, steal when existing
    # $pid: steal only when this pid is in the lock file

    # prepare datastring to write into lockfile
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


    if ($type eq "lock"){
        # lock , only when nonexisting
        if (not -e $DevelConf::lock_file){
           &titel("Creating lock in $DevelConf::lock_file");
           open(LOCK,">$DevelConf::lock_file") || die "Cannot create lock file \n";;
           print LOCK "$lock";
           close(LOCK);
        } else {
           print "Cold not create lock file (file exists already!)\n";
           exit;
        }
    } elsif ($type eq "steal"){
        # steal, only when existing with pid $pid
        my ($l_script,$l_pid)=&read_lockfile();
	if (-e $DevelConf::lock_file
           and $l_pid==$pid){
           &titel("Stealing lock in $DevelConf::lock_file");
           open(LOCK,">$DevelConf::lock_file") || die "Cannot create lock file \n";;
           print LOCK "$lock";
           close(LOCK);
           return 1;
       } else {
           print "Coldnt steal lock file (file vanished! or pid changed)\n";
           exit;
       }
    }
}


sub log_script_start {
    my $stolen=0;
    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $skiplock=0;
    # scripts that are locking the system
    my $log="${timestamp}::start::  $0";
    my $log_locked="${timestamp}::locked:: $0";
    my $count=0;
    foreach my $arg (@arguments){
        $count++;
        # count numbers arguments beginning with 1
        # @arguments numbers arguments beginning with 0
        if ($arg eq "--skiplock"){
            $skiplock=1;
        }

        # change argument of option to xxxxxx if password is expected
        if (exists $DevelConf::forbidden_log_options{$arg}){
            $arguments[$count]="xxxxxx";
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
    my $try_count=0;
    my $max_try_count=5;

    # exit if lockfile exists
    while (-e $DevelConf::lock_file and $skiplock==0){
        my @lock=();
        $try_count++; 
        my ($locking_script,$locking_pid)=&read_lockfile($log_locked);
        if ($try_count==1){
           &titel("sophomorix locked (${locking_script}, PID: $locking_pid)");
        }
        my $ps_string=`ps --pid $locking_pid | grep $locking_pid`;
        $ps_string=~s/\s//g; 

        if ($ps_string eq ""){
            # locking process nonexisting
	    print "PID $locking_pid not running anymore\n";
	    print "   I'm stealing the lockfile\n";
            $stolen=&lock_sophomorix("steal",$locking_pid,@arguments);
            last;
        } else {
	    print "Process with PID $locking_pid is still running\n";
        }

        if ($try_count==$max_try_count){
            &titel("try again later ...");
            my $string = &Sophomorix::SophomorixAPI::fetch_error_string(42);
            &titel($string);
            exit 42;
        } else {
            sleep 1;
        }
    }
    
    if (exists ${DevelConf::lock_scripts}{$0} 
           and $stolen==0
           and $skiplock==0){
	&lock_sophomorix("lock",0,@arguments);
    }
    &titel("$0 started ...");
    &nscd_stop();
}

sub read_lockfile {
    my ($log_locked) = @_;
    open(LOCK,"<$DevelConf::lock_file") || die "Cannot create lock file \n";
    while (<LOCK>) {
        @lock=split(/::/);
    }
    close(LOCK);

    # write to command.log
    if (defined $log_locked){
       open(LOG,">>$DevelConf::log_command");
       print LOG "$log_locked";
       close(LOG);
    }

    my $locking_script=$lock[3];
    my $locking_pid=$lock[4];
    return ($locking_script,$locking_pid);
}


sub log_script_end {
    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $log="${timestamp}::end  ::  $0";
    my $count=0;
    foreach my $arg (@arguments){
        $count++;
        # count numbers arguments beginning with 1
        # @arguments numbers arguments beginning with 0
        # change argument of option to xxxxxx if password is expected
        if (exists $DevelConf::forbidden_log_options{$arg}){
            $arguments[$count]="xxxxxx";
        }
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
    &nscd_start();
    # flush_cache tut nur bei laufendem nscd
    &nscd_flush_cache();
    &titel("$0 terminated regularly");
    exit;
}

sub log_script_exit {
    # 1) what to print to the log file/console
    # (unused when return =!0)
    my $message=shift;
    # 2) return 0: normal end, return=1 unexpected end
    # search with this value in errors.lang 
    my $return=shift;
    # 3) unlock (unused)
    my $unlock=shift;
    # 4) skiplock (unused)
    my $skiplock=shift;

    my @arguments = @_;
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp($timestamp);
    my $log="${timestamp}::exit ::  $0";

    # get correct message
    if ($return!=0){
        if ($return==1){
            # use message given by option 1)
        } else {
            $message = &Sophomorix::SophomorixAPI::fetch_error_string($return);
        }
    } 

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
        #&unlock_sophomorix();
        unlink $DevelConf::lock_file;
    }
    if ($message ne ""){
        &titel("$message");
    }
    &nscd_start();
    exit $return;
}


sub archive_log_entry {
    my ($login) = @_;
    my $file="${DevelConf::log_files}/user-modify.log";
    my $archive="${DevelConf::log_files}/user-modify-archive.log";
    my $today=`date +%d.%m.%Y`;
    chomp($today);

    &check_datei_touch($archive);
    &check_datei_touch($file);

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
	   print "  Log of user $line[2] not ready for archive.\n";
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

    if (-e "${inp}/sophomorix.${str}"){
       &do_falls_nicht_testen(
         "$com ${inp}/sophomorix.${str} ${outp}/${time}.sophomorix.${str}-${str2}",
         # Nur für root lesbar machen
         "chown root:root ${outp}/${time}.sophomorix.${str}-${str2}",
         "chmod 600 ${outp}/${time}.sophomorix.${str}-${str2}"
       );
    }
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
# CYRUS
################################################################################

sub cyrus_fetch_password {
    my $cyrus_pass="";
    # fetch pass from file
    if (-e ${DevelConf::imap_password_file}) {
         # looking for password
 	 open (CONF, ${DevelConf::imap_password_file});
         while (<CONF>){
             chomp();
             if ($_ ne ""){
		 $cyrus_pass=$_;
                 last;
             }
         }
         close(CONF);
    }
    return $cyrus_pass
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
    my ($server, $admin, $silent) = @_;
    if (not defined $silent){
        $silent=0;
    }

    my $imap_pass=&cyrus_fetch_password();
    if($Conf::log_level>=2 and $silent==0){
        # $imap_pass holds password
        print "Connecting to imap-server at $server",
              " as $admin with password *** \n";
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
        print "Password for cyrus in /etc/imap.secret wrong?\n";
        &log_script_exit("",43,1,0,@arguments);
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
    my ($imap,$silent) = @_;
    if (not defined $silent){
        $silent=0;
    }
    if($Conf::log_level>=2 and $silent==0){
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
    my ($imap,$option) = @_;
    if (not defined $option){
        $option="";
    }
    my $count=0;
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
    print "+--------------+---------------------+------+",
          "--------------------+-------------+\n";
    printf "| %-13s| %-20s| %4s | %-19s| %12s|\n",
           "Type/Group","Mailbox","Dirs", "Used Mailquota","Mailquota";
    print "+--------------+---------------------+------+",
          "--------------------+-------------+\n";
    @mailboxes_cleaned = sort @mailboxes_cleaned;
    foreach my $box (@mailboxes_cleaned){
	#print $box,"\n";
        my @data=&imap_fetch_mailquota($imap,$box,1,1);
        my $home="";
        my $group="";
	if ($option eq "showtype"){
            my ($string,$user)=split(/\./,$box);
            ($home,$group)=
               &Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
            if ($group eq ""){
                # mailbox only in cyrus, no system account
                $group="CYRUS";
            }
        } else {
            $group="---";
        } 

        if (defined $data[0]){
           printf "| %-13s| %-20s| %4s | %-19s| %12s|\n",
                  $group,$data[0],$hash{$data[0]},
                  "$data[1] MB","$data[2] MB";
           $count++;
        } else {
           print "$box not found \n";
        }
    }
    print "+--------------+---------------------+------+",
          "--------------------+-------------+\n";
    print "$count mailboxes (use --showtype to show Group/Type of a mailbox)\n";
    print "   Group/Type = 'CYRUS': no unix account matching the box's name exists\n";
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
    #&create_subfolders($imap, $login, @subfolders) or return undef;
    print "Mailbox for $login created.\n";
    return 1;
}

sub imap_rename_mailbox {
    if (not -e ${DevelConf::imap_password_file}) {
        print "WARNING: No file ${DevelConf::imap_password_file}.",
              " Skipping IMAP stuff.\n";
        return 0;
    }
    my ($imap,$old_uid,$new_uid) = @_;


    my $err = $imap->rename("user.$old_uid","user.$new_uid");
    if ($err != 0) {
       	my $status = $imap->error;
        print "$status \n";
    }


    print "Mailbox of $old_uid renamed to $new_uid.\n";
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
	        print "   Mailbox of $login does not exist ...",
                      " nothing to do.\n";
                return 1;
            } else {
                print "$status \n";
		return undef;
	    }
	}
    }
    my $err = $imap->h_delete("user.${login}");
    print "   Return of h_delete is $err (0 = deletion successful)\n";
    if ($err != 0) {
       	my $status = $imap->error;
      	print "$status \n";
       	$imap->close();
       	return undef;
    }
    print "\n";
    #$imap->close();
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
    if (not defined $result[1]){
        # only one partition
        $result[1]="";
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
        # change repairhome.student, ... permissions also, if you change here
        $permission="3750";
    } else {
	$on_off="on";
        # change repairhome.student, ... permissions also, if you change here
        $permission="3757";
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

  if (not -e $from_dir){
      print "ERROR: $from_dir\n",
            "       doesnt exist, Nothing to hand out!\n";
      return;
  }

  # what permissions/owner must i create
  my ($path,$dir_perm,$file_perm)=($to_dir,"0755","0644");

  if ($rsync eq "delete") {
     system("rsync -tor --delete $from_dir $to_dir");
     &chmod_chown_dir($to_dir,$dir_perm,$file_perm,
                      $login,${DevelConf::teacher});
     # system("chmod -R 0755 $to_dir");
  } elsif ($rsync eq "copy"){
     system("rsync -tor $from_dir $to_dir");
     &chmod_chown_dir($to_dir,$dir_perm,$file_perm,
                      $login,${DevelConf::teacher});
     #system("chmod -R 0755 $to_dir");
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
       my $gowner="";
       # what permissions/owner must i create
       my ($path,$dir_perm,$file_perm,
           $smb_owner,$smb_gowner)=&show_smb_conf_umask("homes");
       # owner is set below
       if ($smb_gowner eq ""){
           # should be primary group of user, but is OK
           $gowner=${DevelConf::teacher};
       } else {
           $gowner=$smb_owner;
       }
       foreach my $user (@userlist){
           # home des austeilenden ermitteln
           my $owner="";
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
              if ($smb_owner eq ""){
                  # make user to owner
                  $owner=$user;
              } else {
                  # use smb_owner
                  $owner=$smb_owner;
              }
              &chmod_chown_dir("$to_dir/*",
                               $dir_perm,
                               $file_perm,
                               $owner,$gowner);
              #system ("chown -R ${user}:${DevelConf::teacher} $to_dir/*");
              #system ("chmod -R 0755 $to_dir/*");
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
      # there was no tasks dir before, why ??? 
      @users=&Sophomorix::SophomorixPgLdap::fetchworkstations_from_room($name);
      $tasks_dir="${DevelConf::tasks_rooms}/${name}/";
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
  my $to_dir_above="";
  if (defined $users and $type eq "current room"){ 
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${Language::current_room}/".
                   "${login}_${date}_${Language::current_room}";
         $to_dir_above = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${Language::current_room}";
         &setup_verzeichnis(
                   "\$collected_dir\/\$collected_string\$current_room",
                   "$to_dir_above",
                   "$login");
  } elsif (defined $users) {
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${longname}/".
                   "${login}_${date}_${longname}";
         $to_dir_above = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${longname}";
         &setup_verzeichnis(
                   "\$collected_dir\/\$collected_string\$mygroups",
                   "$to_dir_above",
                   "$login");
  } else {
     if ($exam==1){
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${Language::exam}/".
                    "EXAM_${login}_${date}_${longname}";
         $to_dir_above = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${Language::exam}";
         &setup_verzeichnis(
                   "\$collected_dir\/\$collected_string\$exam",
                   "$to_dir_above",
                   "$login");
     } else {
         $to_dir = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${longname}/".
                   "${login}_${date}_${longname}";
         $to_dir_above = "${homedir_col}/${Language::collected_dir}/".
                   "${Language::collected_string}${longname}";
         &setup_verzeichnis(
                   "\$collected_dir\/\$collected_string\$mygroups",
                   "$to_dir_above",
                   "$login");
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
  system("/bin/chown -R $login. $to_dir");
}



###############################################################################
# HTACCESS-TOOLS
###############################################################################

# users
sub fetchhtaccess_from_user {
    my ($user,$size) = @_;
    if (not defined $size){
        $size="";
    }
    my $upload=0;
    my $public=0,
    my $result="user-";
    my $size_result="";

    my $size_target;
    my $ht_target;
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    if ($type eq "teacher"){
        $size_target=${DevelConf::www_teachers}."/".$user;
        $ht_target=${DevelConf::www_teachers}."/".$user."/.htaccess";
    } elsif ($type eq "student"){
        $size_target=${DevelConf::www_students}."/".$user;
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
    } else {
        return "";
    }

    if (not -e $ht_target){
        print "     * $ht_target not found.\n";
        print "     * Creating .htaccess with standard value.\n";
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

    if ($size eq "size"){
        my $www_size_cmd=`du -sh $size_target`;
	#print "$www_size_cmd";
        chomp($www_size_cmd);
        my ($www_size,$dir) = split(/\s/,$www_size_cmd);
        $size_result = $www_size;
	#print "Size: $www_size\n";
    }

    
    return $result,$size_result;
}

sub user_public_upload {
    my ($user) = @_;
    my ($home,$type)=&Sophomorix::SophomorixPgLdap::fetchdata_from_account($user);
    my $ht_replace= " -e 's/\@\@username\@\@/${user}/g'".
                    " -e 's/\@\@teachergroup\@\@/${DevelConf::teacher}/g'";
    my $ht_template="";
    my $ht_target="";
    my $ht_target_dir="";

    if ($type eq "teacher"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.teacher_public_upload-template";
        $ht_target=${DevelConf::www_teachers}."/".$user."/.htaccess";
        $ht_target_dir=${DevelConf::www_teachers}."/".$user;
    } elsif ($type eq "student"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.student_public_upload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
        $ht_target_dir=${DevelConf::www_students}."/".$user;
    } else {
        # not student, not teacher
        print "     * WARNING: $user is not a student/teacher (type: $type)\n",
              "       (cannot user-public-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (user-public-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;

    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    my $ht_target_dir="";

    if ($type ne "student" and $type ne "attic"){
        print "     * WARNING: $user is not a student/attic (type: $type)\n",
              "       (cannot user-public-noupload)\n";
        return 0;
    } else {
        $ht_template="${DevelConf::apache_templates}"."/".
                     "htaccess.student_public_noupload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
        $ht_target_dir=${DevelConf::www_students}."/".$user;
    }
    
    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (user-public-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    my $ht_target_dir="";

    if ($type eq "teacher"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.teacher_private_upload-template";
        $ht_target=${DevelConf::www_teachers}."/".$user."/.htaccess";
        $ht_target_dir=${DevelConf::www_teachers}."/".$user;
    } elsif ($type eq "student"){
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.student_private_upload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
        $ht_target_dir=${DevelConf::www_students}."/".$user;
    } else {
        # not student, not teacher
        print "     * WARNING: $user is not a student/teacher (type: $type)\n",
              "       (cannot user-private-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (user-private-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    my $ht_target_dir="";

    if ($type ne "student" and $type ne "attic"){
        print "     * WARNING: $user is not a student/attic (type: $type)\n",
              "       (cannot user-private-noupload)\n";
        return 0;
    } else {
        $ht_template="${DevelConf::apache_templates}"."/".
                "htaccess.student_private_noupload-template";
        $ht_target=${DevelConf::www_students}."/".$user."/.htaccess";
        $ht_target_dir=${DevelConf::www_students}."/".$user;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (user-private-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
    chown $uid, $gid, $ht_target;
    return 1;
}







# groups
sub fetchhtaccess_from_group {
    my ($group,$size) = @_;
    if (not defined $size){
        $size="";
    }
    my $upload=0;
    my $public=0,
    my $result="group-";
    my $size_result="";

    my $size_target;
    my $ht_target;
    my ($type,$longname)=
       &Sophomorix::SophomorixPgLdap::pg_get_group_type($group);

    if ($type eq "adminclass"){
        $size_target=${DevelConf::www_classes}."/".$group;
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
    } elsif ($type eq "project"){
        $size_target=${DevelConf::www_projects}."/".$group;
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
    } else {
	return "";
    }

    if (not -e $ht_target){
        print "     * $ht_target not found.\n";
        print "     * Creating .htaccess with standard value.\n";
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

    if ($size eq "size"){
        my $www_size_cmd=`du -h $size_target`;
	#print "$www_size_cmd";
        chomp($www_size_cmd);
        my ($www_size,$dir) = split(/\s/,$www_size_cmd);
        $size_result = $www_size;
	#print "Size: $www_size\n";
    }


    return $result,$size_result;
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
    my $ht_target_dir="";

    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_classes}."/".$group;
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_projects}."/".$group;
    } else {
        # not adminclass, not project
        print "   * WARNING: $group is not a adminclass/project\n",
              "     (cannot group-public-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (group-public-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    my $ht_target_dir="";

    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_classes}."/".$group;
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_projects}."/".$group;
    } else {
        # not adminclass, not project
        print "   * WARNING: $group is not a adminclass/project\n",
              "     (cannot group-public-noupload)\n";
        return 0;
    }
    
    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (group-public-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    my $ht_target_dir="";

    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_classes}."/".$group;
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_projects}."/".$group;
    } else {
        # not adminclass, not project
        print "   * WARNING: $group is not a adminclass/project\n",
              "     (cannot group-private-upload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (group-private-upload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    my $ht_target_dir="";

    if ($type eq "adminclass"){
        $ht_target=${DevelConf::www_classes}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_classes}."/".$group;
    } elsif ($type eq "project"){
        $ht_target=${DevelConf::www_projects}."/".$group."/.htaccess";
        $ht_target_dir=${DevelConf::www_projects}."/".$group;
    } else {
        # not adminclass, not project
        print "   * WARNING: $group is not a adminclass/project\n",
              "     (cannot group-private-noupload)\n";
        return 0;
    }

    # do it
    my $sed_command = "sed $ht_replace $ht_template > $ht_target";
    print "     * modifying $ht_target\n";
    print "       (group-private-noupload)\n";
    if($Conf::log_level>=3){
        print "$sed_command \n";
    }
    system "install -d $ht_target_dir";
    system "$sed_command";
    # setting owner,permissions
    chmod 0400, $ht_target;
    my ($name,$pass,$uid,$gid)=getpwnam(${DevelConf::apache_user});
    print "     * Setting owner/gowner to: ${DevelConf::apache_user}($uid)/".
          "${DevelConf::apache_user}($gid)\n";
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
    } elsif (m/locked by/){
        # debconf is locked
	return undef;
    } else {
       my ($value,$ret)=split(/ /, $result);
       if ($show==1){
          print "$package/$entry: $ret \n";
       }
       return $ret;
    }
}


sub get_debian_version {
    my $version="";
    my $file="/etc/debian_version";
    if (-e $file){
        open(VERSION, $file);
    } else {
        print "\nERROR: Could not determine debian version:\n";
        print "       File $file not found!\n\n";
        return "";
    }
    while (<VERSION>) {
      chomp();
      s/\s//g; # Spezialzeichen raus
      if ($_ ne ""){
          $version=$_;
      }
    }
    return $version;
}


sub get_lsb_release_codename {
    my $codename="";
    my $line=`lsb_release -c`;
    chomp $line;
    $line=~s/Codename://g;
    $line=~s/\s//g; # Spezialzeichen raus
    return $line;
}


sub deb_system {
    my @command_list = @_; 
    my $command_number=($#command_list+1)/2;
    my $deb_installed=&get_debian_version();
    if($Conf::log_level>=2){
        print "deb_system has found $command_number commands\n";
    }
    for (my $i=1;$i<=$command_number;$i++){
        my $deb_version=shift(@command_list);
        my $command=shift(@command_list);
        #print "if $deb_version then $command\n";
        if ($deb_version eq $deb_installed){
            print "Running $command\n";
            system "$command";
        } else {
            if($Conf::log_level>=2){
                print "Not running $command\n";
	    }
        }
    }
}



################################################################################
# ldap stuff 
################################################################################

sub basedn_from_domainname {
   my ($domainname) = @_;
   my @ldapdomains=();
   my (@domains)= split(/\./,$domainname);
   my $dc=$domains[0];
   foreach my $value (@domains) {
       push @ldapdomains, "dc=${value}";
   }
   $basedn = join "," , @ldapdomains;
   return ($basedn,$dc);
}


################################################################################
# immutable bit stuff 
################################################################################

sub unlink_immutable_tree {
    my ($dir,$force) = @_;
    if (not defined $force){
        # do not force removal
	$force=0;
    }
    if (not $dir=~/^\/home\// and $force==0){
        print "unlink_immutable_tree: I do not delete outside /home/\n";
        return 0;
    }
    my $dir_check = $dir;
    $dir_check=~s/\*$//;
    if (not -e $dir_check){
        print "WARNING: Directory/file $dir_check does not exist.\n";
        print "         Doing nothing.\n";
        return 0;
    }
    # remove immutable bit recursively
    # remember and remove immutable bit on parent dir
    my $parent_dir = dirname $dir;
    my $immutable_bit=&fetch_immutable_bit($parent_dir);
    &set_immutable_bit($parent_dir,0);

    if (-x ${DevelConf::chattr_path}){
        system("${DevelConf::chattr_path} -i ${dir}");
        if (-e "${dir}/*"){
            system("${DevelConf::chattr_path} -i -R -f $dir");
        }
    } else {
        print "${DevelConf::chattr_path} not fount/not executable\n";
    }
    # remove dir recursively
    system("rm -rf $dir");

    # restore stored value for immutable bit of parent
    &set_immutable_bit($parent_dir,$immutable_bit);
}



sub move_immutable_tree {
    my ($old_dir,$new_dir) = @_;
    #if (not $old_dir=~/^\/home\//){
    #    print "unlink_immutable_tree: I do not delete outside /home/\n";
    #    return 0;
    #}
    if (not -e $old_dir){
        print "WARNING: Directory/file $old_dir does not exist.\n";
        print "         Doing nothing.\n";
        return 0;
    }
    # remove immutable bit recursively
    # remember and remove immutable bit on parent dir
    my $parent_dir = dirname $old_dir;
    my $immutable_bit=&fetch_immutable_bit($parent_dir);
    &set_immutable_bit($parent_dir,0);

    if (-x ${DevelConf::chattr_path}){
        # operation nicht erlaubt:
        system("${DevelConf::chattr_path} -i -R -f $old_dir");
    } else {
        print "${DevelConf::chattr_path} not fount/not executable\n";
    }
    # move
    system("mkdir -p $new_dir");
    system("mv $old_dir $new_dir");

    # restore stored value for immutable bit of parent
    &set_immutable_bit($parent_dir,$immutable_bit);
}



sub set_immutable_bit {
    my ($dir,$bit) = @_;
    if (not -e $dir){
        print "WARNING: Directory/file $dir does not exist.\n";
        print "         Doing nothing.\n";
        return 0;
    }
    # set immutable bit
    if (-x ${DevelConf::chattr_path}){
        if ($bit==0){
            system("${DevelConf::chattr_path} -i $dir");
        } elsif ($bit==1){
            system("${DevelConf::chattr_path} +i $dir");
        }
    } else {
        print "${DevelConf::chattr_path} not fount/not executable\n";
    }
}

sub fetch_immutable_bit {
    # 0 not set
    # 1 set
    # 2 lsattr executable not found
    # 3 not a filesystem with ext3 bits
    my ($dir) = @_;
    # remove immutable bit recursively
    if (-x ${DevelConf::chattr_path}){
        my $result=`${DevelConf::lsattr_path} -d $dir 2> /dev/null`;
        if ($result eq ""){
            # no result on stdout
            return 3;     
        }
        my ($bits,$res_dir)=split(/ /,$result);
        #print "+++$bits+++\n";
        if ($bits=~/i/){
            # immutable bit is set
            #print "immutable bit SET on $dir\n";
            return 1;
        } else {
            # immutable bit is NOT set
            #print "immutable bit NOT SET on $dir\n";
            return 0;
        }
    } else {
        print "${DevelConf::lsattr_path} not fount/not executable\n";
        return 2;
    }
}






################################################################################
# WEBMIN
################################################################################


################################################################################
# REDIRECT (FORWARD, INGO, ...)
################################################################################


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


sub read_cyrus_redirect {
    my ($user,$print) = @_;
    if (not defined $print){
	$print=0;
    }

    my @redir_list = ();
    my $firstletter = substr($user,0,1);;
    my $file = "/var/spool/sieve/".$firstletter."/".$user."/ingo.script";
    if (-e $file){
        $cross++;
        open(INGO, "<$file");
        while (<INGO>){
            if ($print==1){
                if (m/[0-9a-z;,.:{}\[\]].*/){
                    s/\s$//g; # Spezialzeichen am ende entfernen
   		    print "  $_\n";
                } 
            }
            chomp();
            if (m/redirect/){
                # add email address at the end
                my ($a,$mail_address,$b) = split(/"/);
                push @redir_list, $mail_address;   
            }
            if (m/keep/){
                # add keep at the beginning
                # unshift @redir_list, "keep";   
                push @redir_list, "keep";   
            }
            if (m/discard/){
                push @redir_list, "discard";   
            }
            if (m/stop/){
                push @redir_list, "stop";   
            }
        }
        close(INGO);
        return @redir_list;
    }
    return "";
}



# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
