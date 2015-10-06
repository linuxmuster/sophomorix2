#!/usr/bin/perl -w
# $Id$
# This perl module is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@gmx.de

package Sophomorix::SophomorixTest;
require Exporter;
use Test::More;
#use Time::Local;
#use Time::localtime;

use DBI;

@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw( exchange_line_in_file
              check_line_in_file
              no_line_in_file
              append_line
              remove_line
              check_emptyness
              check_existence
              check_nonexistence
              get_login_name
              kill_user
              check_account
              run_command
              fetch_single_account
              fetch_ldap_account
              fetch_login
              check_file
              check_provided_files
              check_groups
              );

use Sophomorix::SophomorixPgLdap qw ( db_connect
                                  );


# Dieses Modul (SophomorixTest.pm) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

############################################################
# functions to change for sophomorix-pgldap
############################################################

# check_line in_file must be repaced with: check_entry_in_database 
# in the scripts when file is user_db, /etc/passwd ...

# kill_user
# what is this for?
# must not use userdel

# check_account
# must not look in files

############################################################


# exchanging the line, wich is only ONCE in $file
# and  matching $regex with $newline
sub exchange_line_in_file {
    my ($regex,$file,$newline) = @_;
    my %lines=();
    my $count=0;
    my $result="not found";
    open (NEW,">$file.tmp");
    open (OLD,"<$file");
    while (<OLD>){
      #print $_;
      if (/$regex/){
	  $result=$_;
	  #print $result;
          $count++;
          $lines{$result}="";
          print NEW "$newline\n";
      } else {
          print NEW $_;
      }
    }
    close(OLD);
    close(NEW);
    print "   *** Exchange_line_in_file: ";
    if ($count>=2){
       print "Could not exchange lines, I found $count lines! \n";
       $result="  I found $count lines";
       system("rm $file.tmp");
    } elsif ($count==0){
	print "  The regex did not match!\n";
        system("rm $file.tmp");
    } else {
        system("mv $file.tmp $file");
	print "  I successfully replaced ONE line in $file \n";
    }
    return $result;
}


# checks if a line matching $regex is ONCE is $file
sub check_line_in_file {
    my ($regex,$file) = @_;
    my %lines=();
    my $count=0;
    my $result="not found";
    open (READ,"<$file");
    while (<READ>){
      #print $_;
      if (/$regex/){
	  $result=$_;
	  #print $result;
          $count++;
          $lines{$result}="";
      }
    }
    close(READ);
    if (not $count==1){
       $result="I found $count lines";
    }
    chomp($result);
    &like($result,
      qr/$regex/,
      "Line is ONCE in $file");

    return $result;
}

sub no_line_in_file {
    my ($regex,$file) = @_;
    my %lines=();
    my $count=0;
    my $result="not found";
    open (READ,"<$file");
    while (<READ>){
      #print $_;
      if (/$regex/){
	  $result=$_;
	  #print $result;
          $count++;
          $lines{$result}="";
      }
    }
    close(READ);
    is($count, 0 ,"Line deletion successful");
}


sub append_line {
    my ($string,$file) = @_;
    open(SCH,">>$file");
    #print "Appending to $file: \n $string \n\n";
    print SCH "$string\n";
    close(SCH);
}


sub remove_line {
    my $login="";
    my @fields=();
    my $found=0;
    my ($regex,$file) = @_;
    #print "Running on $file \n"; 
    open(SCH,"<$file");
    open(TMP,">$file.tmp");
    while (<SCH>){
      chomp();
      if (/$regex/){
          $found=1;
          print "   *** Removing $_ in $file!\n";
          # remember the login
          @fields=split(/;/);
	  $login=$fields[2];
      } else {
	  print TMP "$_\n";
      }
    }
    close(SCH);
    close(TMP);
    system("mv $file.tmp $file");
    if ($found == 0){
	print "   Could not find Regex $regex \n";
    }
    return $login;
}



sub check_emptyness{
    my ($file) = @_;
    my $exists=0;
    $file="${DevelConf::ergebnis_pfad}/$file";
    if (-s $file){
        $exists=1;
    }
    is("$exists",0,"Check that $file ist leer/nonexistent");
}

sub check_existence{
    my ($file) = @_;
    ok(-e $file,
       "$file exists");
}

sub check_nonexistence{
    my ($file) = @_;
    my $exists=0;
    if (-e $file){
	$exists=1;
    }
    is("$exists",0,"$file is nonexistent");
}

sub get_login_name{
    # parse user_db with $regex
    # return username
    my ($regex) = @_;
    my $login="";
    my @fields=();
    $count=0;
    open(SCH,"<$DevelConf::protokoll_pfad/user_db");
    while (<SCH>){
      chomp();
      if (/$regex/){
          @fields=split(/;/);
	  $login=$fields[2];
          $count++;
      }
    }
    close(SCH);
    if ($count==1){
       return $login;
    } else {
       return $count;
    }
}

sub kill_user {
    my ($login) = @_;
    system("userdel  -r $login");
    system("pdbedit -x -u $login");
    # andere dinge müssen noch gemacht werden
}





sub check_account {
    my ($login,$type) = @_;
    # 2: no account
    # 1: locked account
    # 0: unlocked account
    my $linux_lock=2;
    my $samba_lock=2;
    my $homedir_exists=0;

    # linux
    open(SHADOW, "/etc/shadow");
    while (<SHADOW>){
	if (/$login:/){$linux_lock=0}
	if (/$login:!/){$linux_lock=1}}
    close(SHADOW);
    # samba
    my $pdbedit=`pdbedit -v -u $login`;
    my @pdblines=split(/\n/,$pdbedit);
    foreach (@pdblines){
        if (/Account Flags/){
	    my @item=split(/\s+/);
            #print "Its here:  $item[2]";
            $samba_lock=0;
            if($item[2]=~/D/){$samba_lock=1}
        }
    }
    if ($type eq "disabled"){
       is($linux_lock, 1 ,"Checking if Linux-Account of $login is disabled");
       is($samba_lock, 1 ,"Checking if Samba-Account of $login is disabled");
    } elsif ($type eq "enabled"){
       is($linux_lock, 0 ,"Checking if Linux-Account of $login is enabled");
       is($samba_lock, 0 ,"Checking if Samba-Account of $login is enabled");
    } elsif ($type eq "nonexisting"){
       is($linux_lock, 2 ,"Checking if Linux-Account of $login doesnt exist");
       is($samba_lock, 2 ,"Checking if Samba-Account of $login doesnt exist");
    }

    if ($type ne "nonexisting"){
       # fetching account Data
       my($name,$passwd,$uid,$gid,$quota,$comment,
          $gcos,$dir,$shell) = getpwnam($login);
       my $pri_grp = getgrgid($gid);
#       &check_dir($dir,$login,${DevelConf::teacher},"2701");
       &check_dir($dir,$login,${DevelConf::teacher},"1710");
#       &check_dir("${dir}/${Language::share_dir}","root","root","1755");
#       my $link_dir="${dir}/${Language::share_dir}";
#       &check_links("${link_dir}",$login);

    }

}


sub check_dir {
    # erweiterbar mit acls
    my ($abs_path, $owner, $group, $permissions) = @_;
    my $exists=0;
    # check existence    
    print "Checking: $abs_path \n";
    if (-e $abs_path){
	   $exists=1;
       # reading the permissions
       my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
          $size, $atime, $mtime, $ctime, $blksize, $blocks)
          = stat($abs_path);
       # Umwandeln in übliche Schreibweise
       $mode &=07777;
       $mode=sprintf "%04o",$mode;

       &is($mode,$permissions,
           "Checking permissions of $abs_path to be $permissions");

       # owner name ermitteln
       my ($owner_name)=getpwuid($uid);
       &is($owner,$owner_name,
           "Checking owner of $abs_path to be $owner");
       # group 
       my ($gowner_name)=getgrgid($gid);
       &is($group,$gowner_name,
           "Checking group owner of $abs_path to be $group");
    }

    # show result of existence check
    &is($exists, 1 ,"Checking if  $abs_path exists");
}


sub check_links {
    my ($link_dir, $login) = @_;
    my $exists=0;
    my @checked_links=();
    print "Checking links in $link_dir \n";
    my $grp_string="";
    my $pri_group_string=`id -gn $login`;
    my $group_string=`id -Gn $login`;
    chomp($group_string);
    chomp($pri_group_string);
    my @group_list=split(/ /, $group_string);
    print "Groups of $login: @group_list \n";

    foreach $group (@group_list){
	$exists=0;
#        $link=$link_dir."/Tausch-".$group;
        $link=$link_dir."/${Language::share_string}"."-".$group;
        push @checked_links, $links;
        if (-e $link){
          $exists=1;
          my $link_target = readlink $link;
          print "Target: $link_target \n";
          if ($group eq ${DevelConf::teacher}){    
            &is($link_target,"/home/share/teachers" ,
               "Checking if  target of link is /home/share/classes/${group}");
	  } else {
            &is($link_target,"/home/share/classes/${group}" ,
               "Checking if  target of link is /home/share/classes/${group}");
          }
          # Does Target exist??????
        }
        # show result of existence check
        &is($exists, 1 ,"Checking if  $link is link/exists");
    }

    # lesen, welche Links in $link_dir sind -> Liste
    # alle gecheckten links abziehen
    # es sollten keine restlichen Links übrig sein
    # Link nach schule Testen
}


sub run_command {
    my ($command,$verbose)=@_;
    my $length = length($command);

    my $part1;
    my $part2;
    my $part3;

    $part1 = substr $command, 0 ,70;
    if ($length>70){
        $part2 = substr $command, 70 ,140;
    }
    if ($length>140){
        $part3 = substr $command, 140 ,210;
    }

    print "   *** Running $part1 \n" if defined $part1;
    print "               $part2 \n" if defined $part2;
    print "               $part3 \n" if defined $part3;

    if ($verbose==1){
	system("$command");
    } else {
	system("$command >/dev/null");
    }
}







sub fetch_single_account {
    my ($where) = @_;
    if (not defined $where or $where eq ""){
	$where="";
    } else {   
        $where="WHERE $where";
    }
    my %hash=();
    my $count=0;
    my $ref;
    my $lastref;

    my $dbh=&Sophomorix::SophomorixPgLdap::db_connect();
    my $sql="SELECT * FROM userdata $where";
    if($Conf::log_level>=3){
       print $sql."\n";
    }
    my $sth=$dbh->prepare ($sql);

    $sth->execute();

    while ( $ref = $sth->fetchrow_hashref ){
	$count++;
	#print $ref->{uid},"\n";
        $lastref=$ref;
    } 

    ok($count==1, "($count database entries found!)");    

    if ($count==1){
       %hash=%$lastref;
       if($Conf::log_level>=3){
          print "   Login is: $hash{'uid'} \n";
       }
       &Sophomorix::SophomorixPgLdap::db_disconnect($dbh);
       return %hash;
    } else {
       &Sophomorix::SophomorixPgLdap::db_disconnect($dbh);
       return %hash;
    }

}





sub fetch_ldap_account {
    my ($user) = @_;
    my %entries=();

    my $ldap=&Sophomorix::SophomorixPgLdap::auth_connect();

    my ($ldappw,$ldap_rootdn,$dbpw,$suffix,$mail_dom)=
        &Sophomorix::SophomorixPgLdap::fetch_ldap_pg_passwords();
    my $msg = $ldap->search(
          base => "ou=accounts,$suffix",
          scope => "sub",
          filter => ("uid=$user")
       );
    #print $msg->count(), " entries returned\n";
    my $entry = $msg->entry(0);

    foreach my $attrib ( $entry->attributes() ){
        foreach my $val ( $entry->get_value( $attrib ) ){
            # WARNING: if attrib contains multiple values, then last wins!!!
	    #print $attrib,": ",$val,"\n";
            $entries{$attrib}=$val;
        }
    }
    &Sophomorix::SophomorixPgLdap::auth_disconnect($ldap);
    return %entries;
}





sub fetch_login {
    my ($where) = @_;
    if (not defined $where or $where eq ""){
	$where="";
    } else {   
        $where="WHERE $where";
    }
    my %hash=();
    my $count=0;
    my $ref;
    my $lastref;

    my $dbh=&Sophomorix::SophomorixPgLdap::db_connect();
    my $sql="SELECT * FROM userdata $where";
    if($Conf::log_level>=3){
       print $sql."\n";
    }
    my $sth=$dbh->prepare ($sql);

    $sth->execute();

    while ( $ref = $sth->fetchrow_hashref ){
	$count++;
	#print $ref->{uid},"\n";
        $lastref=$ref;
    } 

    ok($count==1, "($count database entries found!)");    

    if ($count==1){
       %hash=%$lastref;  
       #print "   Login is: $hash{'uid'} \n";
       return $hash{'uid'};
    } else {

      return "";
    }

}




# check all files/directorys/links of a account 
sub check_provided_files {
    my ($login,$class) = @_;

    # the home
    if ($class eq ${DevelConf::teacher}){
        &check_file("",$login,$class,
                    $login,
                    "www-data",
                    "1710");
     } else {
        &check_file("",$login,$class,
                    $login,
                    ${DevelConf::teacher},
                    "3751");
    }

    # cups-pdf
    # is created by cups
    #if ($class eq ${DevelConf::teacher}){
    #    &check_file("cups-pdf",$login,$class,
    #                "administrator",
    #                ${DevelConf::teacher},
    #                "1770");
    #} else {
    #    &check_file("cups-pdf",$login,$class,
    #                "administrator",
    #                ${DevelConf::teacher},
    #                "3757");
    #}

    # private_html
    if ($DevelConf::create_www==1){
       if ($class eq ${DevelConf::teacher}){
           &check_file("private_html",$login,$class,
                       "administrator",
                       "www-data",
                       "3757");
       } else {
           &check_file("private_html",$login,$class,
                       "administrator",
                       "www-data",
                       "3757");
       }
    }

    # __austeilen
    if ($class eq ${DevelConf::teacher}){
        &check_file("$Language::handoutcopy_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
    } else {
        &check_file("$Language::handoutcopy_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "3757");
    }

    # __austeilen/mygroups fehlt ????

    # __austeilen/austeilen-aktueller_raum
    if ($class eq ${DevelConf::teacher}){
        &check_file("__austeilen/austeilen-aktueller_raum",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
    } else {
        &check_file("__austeilen/austeilen-aktueller_raum",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "3757");
    }

    # __dachboden
    if ($class eq ${DevelConf::teacher}){
        &check_file("$Language::user_attic",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
    } else {
        &check_file("$Language::user_attic",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "3757");
    }

    # __einsammeln
    if ($class eq ${DevelConf::teacher}){
       &check_file("$Language::collect_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
    } else {
       &check_file("$Language::collect_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "3757");

    }   

    # __tauschen
    #if ($class eq ${DevelConf::teacher}){
    #   &check_file("$Language::share_dir",$login,$class,
    #                "administrator",
    #                "root",
    #                "1775");
    #} else {
    #   &check_file("$Language::share_dir",$login,$class,
    #                "administrator",
    #                ${DevelConf::teacher},
    #                "3755");
    #}   

    # __vorlagen
    #if ($class eq ${DevelConf::teacher}){
    #   &check_file("$Language::task_dir",$login,$class,
    #                "administrator",
    #                ${DevelConf::teacher},
    #                "1750");
    #} else {
    #   &check_file("$Language::task_dir",$login,$class,
    #                "administrator",
    #                ${DevelConf::teacher},
    #                "3755");
    #}


    #
    # only for teachers
    #

    if ($class eq ${DevelConf::teacher}){
       # _auszuteilen
       &check_file("$Language::to_handoutcopy_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
       &check_file("_auszuteilen/auszuteilen-aktueller_raum",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
       # _auszuteilen/mygroups fehlt ????

       # _bereitstellen
       &check_file("$Language::handout_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
       &check_file("_bereitstellen/bereitstellen-aktueller_raum",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
       &check_file("_bereitstellen/bereitstellen-klassenarbeit",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
       # _bereitstellen/mygroups fehlt ????

       # _eingesammelt
       &check_file("$Language::collected_dir",$login,$class,
                    "administrator",
                    ${DevelConf::teacher},
                    "1770");
       &check_file("_eingesammelt/eingesammelt-aktueller_raum",$login,$class,
                    $login,
                    "root",
                    "0770");
       &check_file("_eingesammelt/eingesammelt-klassenarbeit",$login,$class,
                    $login,
                    "root",
                    "0770");
       # _eingesammelt/mygroups fehlt ????

    }
}









# check a files/directories permissions and owner
sub check_file {
    my ($rel_path,$login,$class,$owner,$gowner,$perm) = @_;

    my $file;
    if ($class eq ${DevelConf::teacher}) {
       $file="/home/${DevelConf::teacher}/$login/$rel_path";
    } else {
       $file="/home/${DevelConf::student}/$class/$login/$rel_path";
    }

    ok(-e $file,"$file  exists");
    my ($dev,$ino,$mode,$nlink,$uid,$gid) = stat(${file});
    # Umwandeln in übliche Schreibweise
    $mode &=07777;
    $mode=sprintf "%04o",$mode;

    my ($group)=getgrgid($gid);
    my ($name)=getpwuid($uid);

#    print "Permissions of $file are $mode, $uid, $gid\n";
#    print "Gruppe: $group \n";
#    print "Login: $name \n";

    is($mode, $perm, "    permissions of $file are $perm");
    is($name, $owner, "    Owner of $file is $owner");
    is($group, $gowner, "    Group owner of $file is $gowner");

}








sub check_groups {

}

sub check_groups_old {
    # param 1 : login
    # param 2 : pri group
    # param 3,4,5,... sec groups
    my $login=shift;
    my @must_groups = @_;
    my $admin_class=$must_groups[0];
    my $share_dir;
    #my $tasks_dir;
    my %is_groups = ( );
    my %is_links_share = ( );
    my %is_links_tasks = ( );

    # calculate where the dir with the share links is
    if ($admin_class eq ${DevelConf::teacher}) {
       $share_dir="/home/${DevelConf::teacher}/$login/${Language::share_dir}";
    } else {
       $share_dir="/home/${DevelConf::student}".
                  "/$admin_class/$login/${Language::share_dir}";
    }

    ## calculate where the dir with the tasks links is
    #if ($admin_class eq ${DevelConf::teacher}) {
    #   $tasks_dir="/home/${DevelConf::teacher}/$login/${Language::task_dir}";
    #} else {
    #   $tasks_dir="/home/${DevelConf::student}".
    #              "/$admin_class/$login/${Language::task_dir}";
    #}

    # the actual groups
    my $is_groups=`id -nG $login`;
    chomp($is_groups);
    my @is_groups=split(/ /,$is_groups);


    # build hash of actual groups of users
    foreach my $is (@is_groups) { $is_groups{$is} = 1 }

    # build hash of actual share links
    opendir SHARE, $share_dir or die "Cannot open $share_dir: $!";
    foreach my $file (readdir SHARE) {
       if ($file eq ".."){next;}
       if ($file eq "."){next;}
       $is_links_share{$file} = 1;
    }
    closedir SHARE;

    # build hash of actual task links
    #opendir TASK, $tasks_dir or die "Cannot open $tasks_dir: $!";
    #foreach my $file (readdir TASK) {
    #   if ($file eq ".."){next;}
    #   if ($file eq "."){next;}
    #   $is_links_tasks{$file} = 1;
    #}
    #closedir TASK;

    # add link to share school if necessary
    my $share_school="${Language::share_string}"."${Language::school}";
    $is_links_share{$share_school} = 1;


    # go through must_groups , and check this
    foreach my $must (@must_groups) {
          # check membership
          ok(exists $is_groups{$must}, "checking if  $login is in group $must");
          delete $is_groups{$must};

          # check link to share
          my $link_goal_rel="";

          if ($must eq ${DevelConf::teacher}){
             $link_goal_rel="${Language::share_string}".
                            "${Language::teacher}";
	  } else {
             $link_goal_rel="${Language::share_string}"."$must";
          }

          my $link_goal="${share_dir}/$link_goal_rel";
          my $must_source="";
          if ($must eq ${DevelConf::teacher}){    
              $must_source="${DevelConf::share_teacher}";
	  } else {
              $must_source="${DevelConf::share_classes}/$must";
          }

          # checking links or binds
          if ($DevelConf::share_pointer_type eq "bind" or
              $DevelConf::share_pointer_type eq "binddir"){
              ok(-d $link_goal, "checking if  $link_goal is a directory");
              delete $is_links_share{$link_goal_rel};
              # test the mount
              if ($DevelConf::share_pointer_type eq "bind"){
                  # ????? $must_source kommt mehrmals vor
                  my $return=`mount | grep $link_goal | grep $must_source |  wc -l`;
                  chomp($return);
                  ok($return eq 1,
                     "I see $return mount of 1 ($link_goal  ->  $must_source)");
	      }
           } elsif ($DevelConf::share_pointer_type eq "symlink"){
              ok(-l $link_goal, "checking if  $link_goal is a link");
              delete $is_links_share{$link_goal_rel};
              if (-l $link_goal){
                 # its a link 
                 my $is_source = readlink $link_goal;

                 # exists the source of the link
                 ok(-e $is_source, "checking if source $is_source exists");

                 # is the source correct
                 is($is_source,
                    $must_source,
                    "Checking if link source is correct"); 
              }
          } else {
                   print "\nWarning: share pointer Type not known\n\n";
          }

          # check link to tasks
          #my $link_goal_rel_tasks="";
          #
          #if ($must eq ${DevelConf::teacher}){
          #   $link_goal_rel_tasks="${Language::task_string}".
          #                        "${Language::teacher}";
	  #} else {
          #   $link_goal_rel_tasks="${Language::task_string}"."$must";
          #}
          #
          #my $link_goal_tasks="${tasks_dir}/$link_goal_rel_tasks";
          #$must_source="";
          #if ($must eq ${DevelConf::teacher}){    
          #    $must_source="${DevelConf::tasks_teachers}";
  	  #} else {
          #    $must_source="${DevelConf::tasks_classes}/$must";
          #}
          ## checking links or binds
          #if ($DevelConf::share_pointer_type eq "bind" or
          #    $DevelConf::share_pointer_type eq "binddir"){
          #    ok(-d $link_goal_tasks, "checking if  $link_goal_tasks is a directory");
          #    delete $is_links_tasks{$link_goal_rel_tasks};
          #    # test the mount
          #    # ?????
          #    if ($DevelConf::share_pointer_type eq "bind"){
          #        my $return=`mount | grep $link_goal_tasks | grep $must_source | wc -l`;
          #        chomp($return);
          #        ok($return==1,
          #           "I see $return mount of 1 ($link_goal_tasks  ->  $must_source)"); 
          #    }
          #} elsif ($DevelConf::share_pointer_type eq "symlink"){
          #    ok(-l $link_goal_tasks, "checking if  $link_goal_tasks is a link");
          #    delete $is_links_tasks{$link_goal_rel_tasks};
          #    my $is_source = readlink $link_goal_tasks;
          #
          #    # exists the source of the link
          #    ok(-e $is_source, "checking if source $is_source exists");
          #
          #    # is the source correct
          #    is($is_source,
          #       $must_source,
          #       "Checking if link source is correct"); 
          #} else {
          #         print "\nWarning: share pointer Type not known\n\n";
          #}
    }

    # are there groups the user is in but shouldn't 
    while (my ($group,$v) = each %is_groups){
       # 1==2 is always wrong
       ok (1==2,"$login is in $group but shouldnt be!");
    }

    # are there links or other files in share but shouldn't
    while (my ($file,$v) = each %is_links_share){
	if ($file eq $share_school){
	    my $abs_file="${share_dir}"."/"."${file}";

            # checking links or binds
            if ($DevelConf::share_pointer_type eq "bind" or 
                $DevelConf::share_pointer_type eq "binddir"){
                ok(-d $abs_file, "checking if $abs_file is a directory");
                # test the mount
                # ???? share_school kommt immer vor ????? 
                if ($DevelConf::share_pointer_type eq "bind"){
                    my $return=`mount | grep $abs_file | grep $share_school | wc -l`;
                    chomp($return);
                    ok($return==1,
                       "I see $return mount of 1 ($abs_file  ->  $share_school)");
                } 
            } elsif ($DevelConf::share_pointer_type eq "symlink"){
                ok(-l $abs_file, "checking if $abs_file is a link");
                my $is_source = readlink $abs_file;
                # exists the source of the link
                ok(-e $is_source, "checking if source $is_source exists");
            } else {
                print "\nWarning: share pointer Type not known\n\n";
            }
       } else {
           ok (1==2,"$file is in $share_dir but shouldnt be!");
       }
    }

    # are there links or other files in tasks but shouldn't
    while (my ($file,$v) = each %is_links_tasks){
	if ($file eq $share_school){
	   my $abs_file="${tasks_dir}"."/"."${file}";
           ok(-l $abs_file, "checking if $abs_file is a link");
           my $is_source = readlink $abs_file;
           # exists the source of the link
           ok(-e $is_source, "checking if source $is_source exists");
       } else {
           ok (1==2,"$file is in $share_dir but shouldnt be!");
       }
    }
}








# EOF
1;
