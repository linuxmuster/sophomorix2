#!/usr/bin/perl -w
# $Id$
# Dieses Modul (SophomorixSYSPgLdap) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de


package Sophomorix::SophomorixSYSPgLdap;
require Exporter;

@ISA =qw(Exporter);
@EXPORT = qw(show_sys_modulename_oldstuff
             update_gecos
             delete_user_from_sys_oldstuff
             add_class_to_sys
             add_user_to_sys
             get_user_auth_data_oldstuff
);

use Sophomorix::SophomorixBase qw ( titel
                                    do_falls_nicht_testen
                                  );

use Sophomorix::SophomorixPgLdap qw ( update_user_db_entry
                                  );



=head1 Documentation of SophomorixSYSPgLdap.pm

The module is used to write/modify sophomorix database information to
the system wich uses files (passwd, group, ...)

=head2 Functions

=over 4

=item  I<show_sys_modulename()>

Shows the name of the actually loaded module

=cut


sub show_sys_modulename {
       &Sophomorix::SophomorixBase::titel("SYS-DB-Module:       SophomorixSYSPgLdap.pm");
}



=pod

=item  I<update_gecos(login, first name, last name)>

Updates the gecos field of login in /etc/passwd

=cut


# OK
sub update_gecos {
   # update the gocos-fiels in /etc/passwd
   my ($login,$first,$last) = @_;
   my $gecos="$first"." "."$last";
   &Sophomorix::SophomorixPgLdap::update_user_db_entry($login,
                      "Gecos=$gecos");
}



sub delete_user_from_sys_oldstuff {
    
}


sub add_class_to_sys {
}


sub add_user_to_sys {

}

sub get_user_auth_data_oldstuff {
    my ($login) = @_;
    # Abfragen der /etc/passwd
    my @data = getpwnam("$login");
    return @data;
}



# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
