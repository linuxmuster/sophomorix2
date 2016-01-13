#!/usr/bin/perl -w

use strict;
use warnings;
use Sophomorix::SophomorixConfig; 

my ($sqlpath,$ldapdc) = @ARGV;

# t.hoth:
#my $sqlpath="/tmp";
#my $ldapdc="dc=linuxmuster,dc=local";

# mail_dom for mail
my $mail_dom=$ldapdc;
$mail_dom=~s/dc=//g;
$mail_dom=~s/,/./g;
# change maildom if configured
if(defined $Conf::alt_mail_domainname){
    $mail_dom=$Conf::alt_mail_domainname;
}

print "# MAILDOM: $mail_dom\n";

# Datei �ffnen und in array schreiben - Datei gleich wieder schlie�en
my @groupsusersfile=();
open(DATEI, "<$sqlpath/groups_users.sql") || die "SQL-Datei nicht gefunden";
push(@groupsusersfile,<DATEI>);
close(DATEI);

my @accountsfile=();
open(DATEI, "<$sqlpath/accounts.sql") || die "SQL-Datei nicht gefunden";
push(@accountsfile,<DATEI>);
close(DATEI);

my @groupsfile=();
open(DATEI, "<$sqlpath/groups.sql") || die "SQL-Datei nicht gefunden";
push(@groupsfile,<DATEI>);
close(DATEI);

my $line="";
my $wert="";
my $name="";
my $uid="";
my $zeileaccounts=1;
my $zeilegroups=1;

# ldap Felder aus Tabellen �berschrift auslesen f�r accounts und groups
my @accountsspalte0 = split(/\|/, $accountsfile[0]); #Zeile0 am | trennen
my @groupsspalte0 = split(/\|/, $groupsfile[0]); #Zeile0 am | trennen


print "# Structure from\n";
print "#   /usr/share/sophomorix/config-templates/ldap/local-gen.ldif\n";
print "# is prepended here\n";

# Alle Zeilen im SQL-Dump-File durchgehen
foreach my $line (@accountsfile) {                          
 my $show_mail=0;
 my @accountsspalte1 = split(/\|/, $line); #Zeile am | trennen
 my $i=0;


  # ???
  # remove after debugging
  #if (not $line=~ /j1016p01/){
  #    next;
  #}


 if ($zeileaccounts > 1) {
  $accountsspalte1[28]=~ s/^\s+//; $accountsspalte1[28]=~ s/\s+$//;
  $accountsspalte1[30]=~ s/^\s+//; $accountsspalte1[30]=~ s/\s+$//;
  $accountsspalte1[31]=~ s/^\s+//; $accountsspalte1[31]=~ s/\s+$//;

  my $ou="accounts";
  # 30 is givenName
  if ($accountsspalte1[30] eq "Computer"){
      $ou="machines";
  }

  print "\n";
  print "dn: uid=$accountsspalte1[28],ou=$ou,$ldapdc\n";
  print "objectClass: inetOrgPerson\n";
  print "objectClass: posixAccount\n";
  print "objectClass: shadowAccount\n";
  print "objectClass: sophomorixData\n";
# does not work
#  print "objectClass: sophomorixData\n";
  print "objectClass: top\n";
  if ($accountsspalte1[1] !~ /^\s*$/) { print "objectClass: sambaSamAccount\n"; };
  
  # disabled, bacause cn follows later
  #print "cn: $accountsspalte1[30] $accountsspalte1[31]\n";
 }

 foreach my $wert (@accountsspalte1) {
  # fuehrende Leerzeichen entfernen
  $wert =~ s/^\s+//;
  $accountsspalte0[$i] =~ s/^\s+//;
  # Leerzeichen am Ende entfernen, auch \n
  $wert =~ s/\s+$//;
  $accountsspalte0[$i] =~ s/\s+$//;

  # ldif schreibweise Konvertierung:

   if ($accountsspalte0[$i]=~ /firstname/) { $accountsspalte0[$i]='givenName'; };
   if ($accountsspalte0[$i]=~ /sambasid/) { $accountsspalte0[$i]='sambaSID'; };
   if ($accountsspalte0[$i]=~ /surname /) { $accountsspalte0[$i]='sn'; };
   if ($accountsspalte0[$i]=~ /homedirectory/) { $accountsspalte0[$i]='homeDirectory'; };
   if ($accountsspalte0[$i]=~ /gecos/) { $accountsspalte0[$i]='gecos'; };
   if ($accountsspalte0[$i]=~ /loginshell/) { $accountsspalte0[$i]='login'; };
   if ($accountsspalte0[$i]=~ /userpassword/) { $accountsspalte0[$i]='userPassword'; };
   if ($accountsspalte0[$i]=~ /description/) { $accountsspalte0[$i]='description'; };
   if ($accountsspalte0[$i]=~ /cn/) { $accountsspalte0[$i]='cn'; };
   if ($accountsspalte0[$i]=~ /sambalmpassword/) { $accountsspalte0[$i]='sambaLMPassword'; };
   if ($accountsspalte0[$i]=~ /sambantpassword/) { $accountsspalte0[$i]='sambaNTPassword'; };
   if ($accountsspalte0[$i]=~ /sambapwdlastset/) { $accountsspalte0[$i]='sambaPwdLastSet'; };
   if ($accountsspalte0[$i]=~ /sambalogontime/) { $accountsspalte0[$i]='sambaLogonTime'; };
   if ($accountsspalte0[$i]=~ /sambalogofftime/) { $accountsspalte0[$i]='sambaLogoffTime'; };
   if ($accountsspalte0[$i]=~ /sambakickofftime/) { $accountsspalte0[$i]='sambaKickoffTime'; };
   if ($accountsspalte0[$i]=~ /sambapwdcanchange/) { $accountsspalte0[$i]='sambaPwdCanChange'; };
   if ($accountsspalte0[$i]=~ /sambapwdmustchange/) { $accountsspalte0[$i]='sambaPwdMustChange'; };
   if ($accountsspalte0[$i]=~ /sambaacctflags/) { $accountsspalte0[$i]='sambaAcctFlags'; };
   if ($accountsspalte0[$i]=~ /displayname/) { $accountsspalte0[$i]='displayName'; };
   if ($accountsspalte0[$i]=~ /sambahomepath/) { $accountsspalte0[$i]='sambaHomePath'; };
   if ($accountsspalte0[$i]=~ /sambahomedrive/) { $accountsspalte0[$i]='sambaHomeDrive'; };
   if ($accountsspalte0[$i]=~ /sambalogonscript/) { $accountsspalte0[$i]='sambaLogonScript'; };
   if ($accountsspalte0[$i]=~ /sambaprofilepath/) { $accountsspalte0[$i]='sambaProfilePath'; };
   if ($accountsspalte0[$i]=~ /sambauserworkstations/) { $accountsspalte0[$i]='sambaUserWorkstations'; };
   if ($accountsspalte0[$i]=~ /sambaprimarygroupsid/) { $accountsspalte0[$i]='sambaPrimaryGroupSID'; };
   if ($accountsspalte0[$i]=~ /sambadomainname/) { $accountsspalte0[$i]='sambaDomainName'; };
   if ($accountsspalte0[$i]=~ /sambamungeddial/) { $accountsspalte0[$i]='sambaMungedDial'; };
   if ($accountsspalte0[$i]=~ /sambabadpasswordcount/) { $accountsspalte0[$i]='sambaBadPasswordCount'; };
   if ($accountsspalte0[$i]=~ /sambabadpasswordtime/) { $accountsspalte0[$i]='sambaBadPasswortTime'; };
   if ($accountsspalte0[$i]=~ /sambapasswordhistory/) { $accountsspalte0[$i]='sambaPasswordHistory'; };
   if ($accountsspalte0[$i]=~ /sambalogonhours/) { $accountsspalte0[$i]='sambaLogonHours'; };
   if ($accountsspalte0[$i]=~ /uidnumber/) { $accountsspalte0[$i]='uidNumber'; };
   if ($accountsspalte0[$i]=~ /uid$/) { $accountsspalte0[$i]='uid'; };
   if ($accountsspalte0[$i]=~ /login/) { $accountsspalte0[$i]='loginShell'; };
   if ($accountsspalte0[$i]=~ /mymail/) { $accountsspalte0[$i]='mail'; };

  # wenn wert nicht leer ist - ausgeben
  if ( ($wert !~ /^\s*$/) && ($zeileaccounts > 1 ) && ($accountsspalte0[$i] !~ /^id/) ){
   
   print "$accountsspalte0[$i]: $wert\n";
   # remember to append mail: to this account
   $show_mail=1;
  }
  $i++;
 }

 # 30 is givenName
 if ($show_mail==1 and $accountsspalte1[30] ne "Computer"
                   and $accountsspalte1[30] ne "Exam"
        ){ 
    # append mail
    if (not defined $accountsspalte1[38] or $accountsspalte1[38] eq "") {
	my $mail=$accountsspalte1[28]."@".$mail_dom;
	print "mail: $mail\n";
    }
 }

$zeileaccounts++;
}

#Gruppen
foreach my $line (@groupsfile) {                          

 my @groupsspalte1 = split(/\|/, $line); #Zeile am | trennen
 my $i=0;
 
 if ($zeilegroups > 1) {
  $groupsspalte1[1]=~ s/^\s+//; $groupsspalte1[1]=~ s/\s+$//;
  print "\n\n";
  print "dn: cn=$groupsspalte1[1],ou=groups,$ldapdc\n";
  print "objectClass: posixGroup\n";
  print "objectClass: sambaGroupMapping\n";
 }

 foreach my $wert (@groupsspalte1) {
  # fuehrende Leerzeichen entfernen
  $wert =~ s/^\s+//;
  $groupsspalte0[$i] =~ s/^\s+//;
  # Leerzeichen am Ende entfernen, auch \n
  $wert =~ s/\s+$//;
  $groupsspalte0[$i] =~ s/\s+$//;

  # ldif schreibweise Konvertierung:

   if ($groupsspalte0[$i]=~ /gidnumber/) { $groupsspalte0[$i]='gidNumber'; };
   if ($groupsspalte0[$i]=~ /sambasid/) { $groupsspalte0[$i]='sambaSID'; };
   if ($groupsspalte0[$i]=~ /sambagrouptype/) { $groupsspalte0[$i]='sambaGroupType'; };
   if ($groupsspalte0[$i]=~ /gidnumber/) { $groupsspalte0[$i]='gidNumber'; };
   if ($groupsspalte0[$i]=~ /displayname/) { $groupsspalte0[$i]='displayName'; };
   if ($groupsspalte0[$i]=~ /sambasidlist/) { $groupsspalte0[$i]='sambaSIDList'; };
   if ($groupsspalte0[$i]=~ /gid$/) { $groupsspalte0[$i]='cn'; };

  # wenn wert nicht leer ist - ausgeben
  if ( ($wert !~ /^\s*$/) && ($zeilegroups > 1 ) && ($groupsspalte0[$i] !~ /^id/) ){
   print "$groupsspalte0[$i]: $wert\n";
  
  # Benutzer - Gruppen zuordnung
   foreach my $line (@groupsusersfile) {
    my @groupsusersspalte = split(/\|/, $line); #Zeile am | trennen
     # whitespace vorne entfernen
     $groupsusersspalte[0] =~ s/^\s+//;
     # whitespace hinten entfernen
     $groupsusersspalte[0] =~ s/\s+$//;
    if ( ($groupsusersspalte[0] eq $wert) && ($groupsspalte0[$i]=~ /cn/) ){
     # whitespace vorne entfernen
     $groupsusersspalte[1] =~ s/^\s+//;
     # whitespace hinten entfernen
     $groupsusersspalte[1] =~ s/\s+$//;
     print "memberUid: $groupsusersspalte[1]\n"; 
     
    };
   }
  }
  $i++;
 } 
$zeilegroups++;
} 
