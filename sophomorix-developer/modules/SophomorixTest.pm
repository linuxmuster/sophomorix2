#!/usr/bin/perl -w
package Sophomorix::SophomorixTest;
require Exporter;
use Test::More;
#use Time::Local;
#use Time::localtime;

@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw( exchange_line_in_file
              check_line_in_file
              append_line
              remove_line
              check_emptyness
              check_existence
              get_login_name
              kill_user
              check_account
              run_command
              );

# Dieses Modul (SophomorixTest.pm) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de



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
      "Line is exactly ONCE in $file");

    return $result;
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
    my ($regex,$file) = @_;
    #print "Running on $file \n"; 
    open(SCH,"<$file");
    open(TMP,">$file.tmp");
    while (<SCH>){
      chomp();
      if (/$regex/){
          print "   Removing a line in $file!\n";
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
    return $login;
}



sub check_emptyness{
    my ($file) = @_;
    ok('-z "${DevelConf::ergebnis_pfad}/$file"',
       "$file ist leer/nonexistent");
}

sub check_existence{
    my ($file) = @_;
    ok(-e $file,
       "$file existiert");
}

sub get_login_name{
    # parse user.protokoll with $regex
    # return username
    my ($regex) = @_;
    my $login="";
    my @fields=();
    $count=0;
    open(SCH,"<$DevelConf::protokoll_pfad/user.protokoll");
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

# EOF
1;
