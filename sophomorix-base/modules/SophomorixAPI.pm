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
             get_user_adminclass
             get_pupils_school
             get_adminclasses_school
             get_workstations_room
             get_workstations_school
             get_rooms_school
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

=head2 Query users or groups of users 

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

=item I<get_user_adminclass(AdminClass)>

Returns an asciibetical list of all users in this AdminClass. The
AdminClass is the class of a pupil in the school administration
software.

If you need a list of teachers then use their primary group
(i.e. lehrer) as AdminClass

If no pupil is in this class, an empty list will be returned.

=cut


sub get_user_adminclass {
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

#         if (($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/pupil\// ) or
#             ($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/teacher\// )) {
         if (($pwliste[3] eq $gid && $pwliste[7]=~/^$DevelConf::homedir_pupil/) or
             ($pwliste[3] eq $gid && $pwliste[7]=~/^$DevelConf::homedir_teacher/)) {
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



=pod

=item I<get_pupils_school()>

Returns an asciibetical list of all pupils in the school. No teachers
are returned

=cut

sub get_pupils_school {
    my @pwliste=();
    my @schuelerliste=();
    
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]";  # Das 8. Element ist das Home-Verzeichnis
 #     if ($pwliste[7]=~/^\/home\/pupil\//) {
       if ($pwliste[7]=~/^$DevelConf::homedir_pupil/) {
       push(@schuelerliste, $pwliste[0]);
         #print "$pwliste[0]<p>";
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @schuelerliste = sort @schuelerliste;
    return @schuelerliste;
}








=pod

=item I<get_adminclasses_school()>

Returns an asciibetical list of all AdminClasses in the school. 
The group of all teachers is NOT included in this list

=cut

# Diese Funktion liefert eine Liste aller Klassen der Schule zurück
sub get_adminclasses_school {
    my @pwliste;
    my %klassen_hash=();
    my @liste;
    # Alle Klassen-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
#       if ($pwliste[7]=~/^\/home\/pupil\//) {
       if ($pwliste[7]=~/^$DevelConf::homedir_pupil/) {
          $klassen_hash{getgrgid($pwliste[3])}=""; 
       }
    }
    endpwent();

    while (my ($k) = each %klassen_hash){
       # Liste füllen
       push (@liste, $k);
    }
    
    @liste = sort @liste;
    return @liste;
}

=pod

=head2 Query workstations  or rooms (group of workstations) 

=over 4

=item I<get_workstations_room(Room)>

Returns an asciibetical list of all workstations in the Room. 

=cut

sub get_workstations_room {
    my ($room)=@_;
    #print "$room<p>";
    my @pwliste=();
    my @workstations=();
    # Group-ID ermitteln
    my ($a,$b,$gid) = getgrnam $room; 
    #print"Info: Group-ID der Gruppe $room ist $gid<p>\n";

    
    if (not defined $gid){
        return @workstations;
    } else {
       # alle Workstations in diesem Raum heraussuchen
       setpwent();
       while (@pwliste=getpwent()) {
       #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis
#        if ($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/workstations\//) {
         if ($pwliste[3] eq $gid && $pwliste[7]=~/^$DevelConf::homedir_ws/) {
             push(@workstations, $pwliste[0]);
             #print "$pwliste[3]";
         }
       }
       endpwent();
    
       # Alphabetisch ordnen
       @workstations=sort @workstations;
       return @workstations;
    }
}


=pod

=item I<get_adminclasses_school()>

Returns an asciibetical list of all AdminClasses in the school. 
The group of all teachers is NOT included in this list

=cut



sub get_rooms_school {
    my @pwliste;
    my %raeume_hash=();
    my @liste;
    # Alle Raeume-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
#       if ($pwliste[7]=~/^\/home\/workstations\//) {
       if ($pwliste[7]=~/^$DevelConf::homedir_ws/) {
          $raeume_hash{getgrgid($pwliste[3])}=""; 
       }
    }
    endpwent();

    while (my ($k) = each %raeume_hash){
       # Liste füllen
       push (@liste, $k);
    }
    
    @liste = sort @liste;
    return @liste;
}


sub get_workstations_school {
    my @pwliste=();
    my @workstationliste=();
    
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]";  # Das 8. Element ist das Home-Verzeichnis
#      if ($pwliste[7]=~/^\/home\/workstations\//) {
      if ($pwliste[7]=~/^$DevelConf::homedir_ws/) {
         push(@workstationliste, $pwliste[0]);
         #print "$pwliste[0]<p>";
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @workstationliste = sort @workstationliste;
    return @workstationliste;
}









# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
