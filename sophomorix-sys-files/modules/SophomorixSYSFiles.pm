#!/usr/bin/perl -w
# Dieses Modul (SophomorixSYSFiles) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de


package Sophomorix::SophomorixSYSFiles;
require Exporter;

@ISA =qw(Exporter);
@EXPORT = qw(show_sys_modulename
             update_gecos
             delete_user_from_sys
             add_class_to_sys
             add_user_to_sys
             get_user_auth_data
);

use Sophomorix::SophomorixBase qw ( titel
                                    do_falls_nicht_testen
                                  );



=head1 Documentation of SophomorixSYSFiles.pm

The module is used to write/modify sophomorix database information to
the system wich uses files (passwd, group, ...)

=head2 Functions

=over 4

=item  I<show_sys_modulename()>

Shows the name of the actually loaded module

=cut


sub show_sys_modulename {
#    if($Conf::log_level>=2){
       &Sophomorix::SophomorixBase::titel("SYS-DB-Module:       SophomorixSYSFiles.pm");

#   }
}




=pod

=item  I<update_gecos(login, first name, last name)>

Updates the gecos field of login in /etc/passwd

=cut

sub update_gecos {
   # update the gocos-fiels in /etc/passwd
   my ($login,$first,$last) = @_;
   my $gecos="$first"." "."$last";
   system("usermod -c '$gecos' $login");
}

=pod

=item  I<delete_user_from_sys(login)>

Deletes the user I<login> in F<passwd>, F<samba> and removes her home
directory for good.

=cut

sub delete_user_from_sys {
    ($login)=@_;
    &Sophomorix::SophomorixBase::do_falls_nicht_testen(
       # aus smbpasswd entfernen
       "/usr/bin/smbpasswd  -x $login",
       # Aus Benutzerdatenbank entfernen (-r: Home löschen)
       "userdel  -r $login",
    );
}

=pod

=item  I<add_class_to_sys(class, gid)>

Adds the group I<class> to the system database.


=cut

sub add_class_to_sys {
    ($class,$gid)=@_;
    if ($gid eq "---" or not defined $gid or $gid eq ""){
       &Sophomorix::SophomorixBase::do_falls_nicht_testen(
          "groupadd $class",
       );
   } else {
       &Sophomorix::SophomorixBase::do_falls_nicht_testen(
          "groupadd -g $gid $class",
       );
   }
}


=pod

=item  I<add_user_to_sys(class)>

Adds the user I<user> to the system database.


=cut

sub add_user_to_sys {
    my ($nachname,
       $vorname,
       $gebdat,
       $class,
       $login,
       $pass,
       $sh,
       $wunsch_id) = @_;

    my $gec = "$vorname"." "."$nachname";
    my $home ="";
    if ($class eq "lehrer"){
       $home = "${DevelConf::homedir_teacher}/$login";
    } else {
       $home = "${DevelConf::homedir_pupil}/$class/$login";
    }
    if ($wunsch_id eq "---"){
       &Sophomorix::SophomorixBase::do_falls_nicht_testen(
          "useradd -c '$gec' -d $home -m -g $class -p $pass -s $sh $login"
       );
    } else {
       &Sophomorix::SophomorixBase::do_falls_nicht_testen(
          "useradd -c '$gec' -d $home -m -g $class -p $pass -s $sh $login -u $wunsch_id"
#         "useradd -c '$gec' -m -g $class -p $pass -s $sh $login"
    );
    }
}



=pod

=item  I<get_user_auth_data(login)>

Retrieves data as in getpwnam Does getpwnam also work with ldap, sql? 


=cut
sub get_user_auth_data {
    my ($login) = @_;
    # Abfragen der /etc/passwd
    my @data = getpwnam("$login");
    return @data;
}












# OK







# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
