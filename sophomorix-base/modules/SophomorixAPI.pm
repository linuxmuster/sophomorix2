#!/usr/bin/perl -w
# Dieses Modul (SophomorixAPI.pm) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

# aufspalten in:  
#    SophomorixBase
#    SophomorixQuota
#    SophomorixSamba
#    SophomorixAPI

package Sophomorix::SophomorixAPI;
require Exporter;
use Time::Local;
use Time::localtime;


@ISA = qw(Exporter);

@EXPORT_OK = qw( check_datei_touch );
@EXPORT = qw( 
             get_user_in_adminclass
            );




# wenn diese Zeile da steht dann muss in SophomorixSYSFiles.pm immer
# wenn eine Funktion aus SophomorixBase.pm genutzt wird der absolute Pfad
# &Sophomorix::SophomorixBase::titel() angegeben werden.
# Es wir nach der Funktion in Sophomorix::SophomorixSYSFiles::titel gesucht

use Sophomorix::SophomorixSYSFiles qw ( 
                                    get_user_auth_data
                                  );




#use Sophomorix::SophomorixFiles qw ( 
#                                    update_user_db_entry
#                                  );





=head1 Documentation of SophomorixAPI.pm


B<sophomorix> is a user administration tool for a school server. It
lets you administrate a huge amount of users by exporting all pupils of
a school into a file and reading them into a linux system.

B<Sophomorix> will in the future use different backends (files, ldap,
SQL-Databases, ...) to store its data. If you want to access this data
you could talk to the backend directly, but this would mean, that you
would have to update your scripts when the data organisation in the
backend changes.

A better way is to ONLY use the functions of B<SophomorixAPI>. So if
the data organisation changes you only have to get a current version
of B<SophomorixAPI> and you're done.

A very good example, when you should use SophomorixAPI.pm is writing
webmin modules for sophomorix.


=head2 FUNCTIONS

=head2 Querys

=over 4

=cut
    my $develconf="/usr/share/sophomorix/devel/sophomorix-devel.conf";
if (not -e $develconf){
    print "ERROR: $develconf not found!\n";
    exit;
}

# Einlesen der Konfigurationsdatei für Entwickler
#{ package DevelConf ; do "/etc/sophomorix/devel/user/sophomorix-devel.conf"}
{ package DevelConf ; do "$develconf"}

# Einlesen der Konfigurationsdatei
{ package Conf ; do "${DevelConf::config_pfad}/sophomorix.conf"}
# Die in sophomorix.conf als global (ohne my) deklarierten Variablen
# können nun mit $Conf::Variablenname angesprochen werden



# ===========================================================================
# Liste der Schüler einer Klasse ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion hat als Argument einen Gruppennamen
# Sie liefert alle Schüler dieser Klasse zurück
# Wenn keine Schüler in dieser Gruppe sind wird eine leere Liste zurückgegeben

=pod

=item I<get_user_in_adminclass(class)>

Returns a list of all users in this AdminClass. The AdminClass is the
class of a pupil in the school administration software. 

If no pupil is in this class an empty list will be returned.

=cut


sub get_user_in_adminclass {
    my ($klasse) = @_;
    my @pwliste=();
    my @userliste=();
    if ($klasse eq "" or not defined $klasse){
        print "No class given\n",
	return @userliste;
    } else {
      # Group-ID ermitteln
      my ($a,$b,$gid) = getgrnam $klasse; 
      #print"Info: Group-ID der Gruppe $klasse ist $gid<p>\n";
      if (not defined $gid){
        return @userliste;
      } else {
        # alle Schüler in dieser Gruppe heraussuchen
        setpwent();
        while (@pwliste=getpwent()) {
        #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis

         if (($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/pupil\// ) or
             ($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/teacher\// )) {
             push(@userliste, $pwliste[0]);
             #print "$pwliste[3]";
         }
        }
        endpwent();

        # Alphabetisch ordnen
        @userliste=sort @userliste;
        return @userliste;
      } 
  }
}




# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
