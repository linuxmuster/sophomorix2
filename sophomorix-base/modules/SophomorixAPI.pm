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
use Sophomorix::SophomorixPgLdap;
use Sophomorix::SophomorixBase qw ( 
                                    create_share_link
                                    remove_share_link
                                  );


@ISA = qw(Exporter);

@EXPORT_OK = qw( check_datei_touch );
@EXPORT = qw( 
             fetchstudents_from_school
             create_userlist
             get_ml_users
             add_my_adminclass
             remove_my_adminclass
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
lets you administrate a huge amount of users by exporting all students of
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


=head2 SYNOPSIS

   # This is for configuration variables
   use Sophomorix::SophomorixConfig;

   # This is for functions in SophomorixAPI
   use Sophomorix::SophomorixAPI;
   
   # access variables in sophomorix.conf    
   my $school = $Conf::schul_name;
 
   # access variables in sophomorix-devel.conf    
   my $smb_home = $DevelConf::homedir_samba_netlogon;

   # access variables in sophomorix-lang.NAME
   # where NAME is one of de, en, ...    
   my $directory = $Language::collect_dir;


Note: If you want to use funcions you have to use BOTH packages
(SophomorixConfig AND SophomorixAPI, in this order)



=pod

=head2 TODO: FUNCTIONS from Sophomorix::SophomorixPgldap to put here:
  (Top priority is on top)

  function1
  function2

=cut

=pod

=head2 FUNCTIONS

=head2 Query users or groups of users 

=over 4

=cut


=item I<@list = fetchstudents_from_school()>

Returns an asciibetical list of all students of the school. No teachers
are returned

=cut

# replaces get_students_school
sub fetchstudents_from_school {
    my @students=();
    my $dbh=&db_connect();
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uid 
                             FROM userdata 
                             WHERE (gid!='teachers' 
                               AND sophomorixstatus!='') 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($uidnumber)=@$row;
       push @students, $uidnumber;
    }

    &db_disconnect($dbh);
    return @students;

}




=pod

=item ??? I<@list = get_adminclasses_school()>

Returns an asciibetical list of all AdminClasses in the school. 
The group of all teachers is NOT included in this list

=cut


# function fetchadminclasses_from_school



=pod

=item ??? I<@list = get_adminclasses_sub_school()>

Returns an asciibetical list of all AdminClasses with subclasses in the school. 
The group of all teachers is NOT included in this list

=cut

sub get_adminclasses_sub_school_oldstuff {
    # this is database-dependant ?????????????
    my $file="$DevelConf::protokoll_datei";
    my %klassen_hash=();
    my @liste;
    open(DB, "<$file");
    while(<DB>){
        chomp();
        if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
        if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
        my @line=split(/;/);
        if (not defined $line[6]){
            $line[6]="";
	}
        if ($line[6] eq "A" or
            $line[6] eq "B" or
            $line[6] eq "C" or
            $line[6] eq "D"){
            # print "Class: $line[0]\n"; 
            # print "  Sub:  $line[6]\n"; 
            $klassen_hash{$line[0]}="";
        }
    }

    close(DB);
    while (my ($k) = each %klassen_hash){
       # Liste füllen
       push (@liste, $k);
    }
    
    @liste = sort @liste;
    return @liste;
}

=pod

=item ??? I<@list = get_projects_school()>

Returns an asciibetical list (short name = linux name) of all projects
in the school.

=cut

# Diese Funktion liefert eine Liste aller Klassen der Schule zurück
sub get_projects_school_oldstuff {
    # this is database-dependant ?????????????
    my $file="${DevelConf::protokoll_pfad}/projects_db";
    my %projects=();
    my @liste;
    open(DB, "<$file");
    while(<DB>){
        chomp();
        if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
        if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
        my @line=split(/;/);
        $projects{$line[0]}="";
    }
    close(DB);
    while (my ($k) = each %projects){
       # Liste füllen
       push (@liste, $k);
    }
    
    @liste = sort @liste;
    return @liste;
}

=pod

=head2 Query workstations  or rooms (group of workstations) 

=over 4

=item ??? I<@list = get_workstations_room(Room)>

Returns an asciibetical list of all workstations in the room Room. 

=cut

sub get_workstations_room_old_stuff {
    my ($room)=@_;
    #print "$room<p>";
    my @pwliste=();
    my @workstations=();
    # Group-ID ermitteln
    my ($a,$b,$gid) = getgrnam $room; 
    
    if (not defined $gid){
        return @workstations;
    } else {
       # alle Workstations in diesem Raum heraussuchen
       setpwent();
       while (@pwliste=getpwent()) {
       #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis
         if ($pwliste[3] eq $gid && $pwliste[7]=~/^$DevelConf::homedir_ws/) {
             push(@workstations, $pwliste[0]);
         }
       }
       endpwent();
    
       # Alphabetisch ordnen
       @workstations=sort @workstations;
       return @workstations;
    }
}


=pod

=item ??? I<@list = get_adminclasses_school()>

Returns an asciibetical list of all AdminClasses in the school. 
The group of all teachers is NOT included in this list

=cut



sub get_rooms_school_oldstuff {
    my @pwliste;
    my %raeume_hash=();
    my @liste;
    # Alle Raeume-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
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


=pod

=item ??? I<@list = get_workstations_school()>

Returns an asciibetical list of all Workstations in the school. 

=cut


sub get_workstations_school_oldstuff {
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




=pod

=item ??? May not work: I<@list = create_userlist(logins,classes,students,rooms,workstations,check)>

Creates a ascibetical list of users, that are specified with the
parameters. The parameters are:

logins:       comma seperated list of logins

classes:      comma seperated list of AdminClasses, (can also be teachers)

students:     add the list of all students (1), or not (0)

rooms:        comma seperated list of rooms

workstations: add the list of all workstations (1), or not (0)

check:        check (1) every loginname if it is a valid student,teacher 

              or workstation or not (0)

Option check makes this function very slow!

=cut



sub create_userlist {
    my @userlist=();
    my %logins=();
    my @unique_userlist=();
    my ($login, $classes, $pupil, $rooms, $ws,$check) = @_;
    if (not defined $login){$login=""}   
    if (not defined $classes){$classes=""}   
    if (not defined $pupil){$pupil=0}   
    if (not defined $rooms){$rooms=""}   
    if (not defined $ws){$ws=0}   
    if (not defined $check){$check=0}   

    # loginnames
    if ($login ne "") {
       my (@loginlist)=split(/,/,$login);
       push @userlist, @loginlist;
    }

    if ($classes ne "") {
       my @users=();
       my (@classlist)=split(/,/,$classes);
       foreach my $class (@classlist){
          @users=&fetchstudents_from_adminclass($class);
          push @userlist, @users;
       }
     }

     if ($pupil==1) {
        my @users=();
        @users=&fetchstudents_from_school();
        push @userlist, @users;
     }

     if ($rooms ne "") {
        my @users=();
        my (@roomlist)=split(/,/,$rooms);
        foreach my $room (@roomlist){
#           @users=&get_workstations_room($room);
           @users=&fetchworkstations_from_room($room);
           push @userlist, @users;
        }
      }

      if ($ws==1) {
        my @users=();
#        @users=&get_workstations_school();
        @users=&fetchworkstations_from_school();
        push @userlist, @users;
      }


      # create userlist
      if ($check==1 and not $#userlist+1==0){
       %logins=&get_ml_users();
      }


      # remove doules/check
      foreach my $item (@userlist) {
         unless ($seen{$item}) {
            # if we get here, we have not seen it before
            $seen{$item} = 1;
            if ($check==0){
                  # dont check
                  push(@unique_userlist, $item);
	    } else {
               # check
               if (exists $logins{$item}){
                  push(@unique_userlist, $item);
	       } else {
                  print "INFO: $item is not a ml user, skipping $item ...\n";
               }
            }
         } else {
            if($Conf::log_level>=3){
               print "User $item is already in the list\n";
            }
         }
     }

     # order asciibetical
     @unique_userlist = sort @unique_userlist;
    return @unique_userlist;
}




=pod

=item ??? I<%hash = get_ml_users()>

Returns an hash with ALL ml login names. This includes:
  - pupil, teachers (sophomorix database)
  - workstations

The value is one of teacher, student or workstation

=cut

sub get_ml_users {
    my @pwliste=();
    my %ml_hash=();
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis
       if ($pwliste[7]=~/^$DevelConf::homedir_pupil/) {
	   $ml_hash{$pwliste[0]}="student";
         #print "$pwliste[0]\n";
       }
       if ($pwliste[7]=~/^$DevelConf::homedir_teacher/) {
	   $ml_hash{$pwliste[0]}="teacher";
         #print "$pwliste[0]\n";
      }
       if ($pwliste[7]=~/^$DevelConf::homedir_ws/) {
	   $ml_hash{$pwliste[0]}="workstation";
         #print "$pwliste[0]<p>";
      }
    }
    endpwent();
    return %ml_hash;
}



=pod

=item I<add_my_adminclass(Login,AdminClass)>

Adds the valid AdminClass to MyAdminClasses of the user Login.

=cut

sub add_my_adminclass {
    my ($login,$class) = @_;

    # add my adminclass to database
    &addadmin_to_adminclass($login,$class);

    # create link
    &Sophomorix::SophomorixBase::create_share_link($login,
         $class,$class,"adminclass");

    # join group
    &pg_adduser($login,$class);

    # create dirs in tasks and collect
    &Sophomorix::SophomorixBase::create_share_directory($login,
         $class,$class,"adminclass");

    # fetch a list of subclasses
    my @subs=&Sophomorix::SophomorixPgLdap::fetch_used_subclasses($class);
    foreach my $sub (@subs){
	my $subclass=$class."-".$sub;
        # create link
        &Sophomorix::SophomorixBase::create_share_link($login,
            $subclass,$subclass,"subclass");
        # join group
        &pg_adduser($login,$subclass);
        # create dirs in tasks and collect
        &Sophomorix::SophomorixBase::create_share_directory($login,
            $subclass,$subclass,"subclass");
   }
}



=pod

=item I<remove_my_adminclass(Login,AdminClass)>

Removes AdminClass from the classes of the user Login and returns 1;.

If the class could not be removed (because it didn't exist in
MyAdminClasses), 0 is returned.

=cut

sub remove_my_adminclass {
    my ($login,$class) = @_;

    # remove my adminclass from database
    &deleteadmin_from_adminclass($login,$class);

    # remove link
    &Sophomorix::SophomorixBase::remove_share_link($login,
         $class,$class,"adminclass");

    # remove dirs in tasks and collect
    &Sophomorix::SophomorixBase::remove_share_directory($login,
         $class,$class,"adminclass");

    # fetch a list of subclasses
    my @subs=&Sophomorix::SophomorixPgLdap::fetch_used_subclasses($class);
    foreach my $sub (@subs){
	my $subclass=$class."-".$sub;
        # remove link
        &Sophomorix::SophomorixBase::remove_share_link($login,
            $subclass,$subclass,"subclass");
        # join group
        &pg_adduser($login,$subclass);
        # remove dirs in tasks and collect
        &Sophomorix::SophomorixBase::remove_share_directory($login,
            $subclass,$subclass,"subclass");
   }
}





# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
