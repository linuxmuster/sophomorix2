#!/usr/bin/perl -w
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
              get_login_name
              kill_user
              check_account
              run_command
              fetch_single_account
              fetch_login
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
    print "   exchange_line_in_file: ";
    if ($count>=2){
       print "Could not exchange lines, I found $count lines! \n";
       $result="  I found $count lines";
       system("rm $file.tmp");
    } elsif ($count==0){
	print "  The regex did not match!\n";
        system("rm $file.tmp");
    } else {
        system("mv $file.tmp $file");
	print "  I succesfully replaced ONE line in $file \n";
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
    is($count, 0 ,"Line deletion succesful");
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
          print "   Removing $_ in $file!\n";
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
       "$file existiert");
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
       &check_dir($dir,$login,${DevelConf::teacher},"0700");
       &check_dir("${dir}/windows",$login,${DevelConf::teacher},"0700");
       &check_dir("${dir}/${Language::share_dir}","root","root","1755");
       my $link_dir="${dir}/${Language::share_dir}";
       &check_links("${link_dir}",$login);

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

    # show result of existance check
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
          # Does Target exist??????ßß
        }
        # show result of existance check
        &is($exists, 1 ,"Checking if  $link is link/exists");
    }

    # lesen, welche Links in $link_dir sind -> Liste
    # alle gecheckten links abziehen
    # es sollten keine restlichen Links übrig sein
    # Link nach schule Testen
}


sub run_command {
    my ($command,$verbose)=@_;
    print "Running $command \n";
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
    print $sql."\n";

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
       print "   Login is: $hash{'uid'} \n";
       return %hash;
    } else {

       return %hash;
    }

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
    print $sql."\n";

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
       print "   Login is: $hash{'uid'} \n";
       return $hash{'uid'};
    } else {

      return "";
    }

}








# EOF
1;
