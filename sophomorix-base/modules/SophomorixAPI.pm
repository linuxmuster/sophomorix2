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
             get_user_project
             create_userlist
             get_ml_users
             get_my_adminclasses
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


=pod

=item I<get_workstations_school()>

Returns an asciibetical list of all Workstations in the school. 

=cut


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



=pod

=item I<get_user_project(Teachers,Members,MemberGroups)>

Teachers,Members,MemberGroups are the fields in projects_db. A
function to get this fields will follow.

=cut


sub get_user_project {
    my %users=();
    my @group_users=();
    my @users_pri=();
    my @users_sec=();
    my %seen=();
    my ($project,$teachers,$members,$member_groups) = @_;
    # the new teachers
    my @new_teachers=split(/,/, $teachers);
    # the new users (without groups)
    my @new_users=split(/,/, $members);
    # the new groups
    my @new_groups=split(/,/, $member_groups);    
    if($Conf::log_level>=2){
       print "Project $project \n";
       print "   New Teachers      : @new_teachers\n";
       print "   New Members       : @new_users\n";
       print "   New MemberGroups  : @new_groups\n";

    }

    # Add the teachers
    foreach my $teacher (@new_teachers){
       if (not exists $users{$teacher}){
	  $users{$teacher}="Teachers";
       }
    }

    # Add the users
    foreach my $user (@new_users){
       if (not exists $users{$user}){
          $users{$user}="Members";
       }
    }

    # Add the users in the groups
    foreach my $group (@new_groups){
        my $group_users="";
        if (exists $seen{$group}){
	    print "Aaaargh, I have seen group $group! \n",
                  "Are you using recursive/multiple groups ...?\n";
            next;
        }
        # remember the group
        $seen{$group}="seen";
        if ($group eq $project){
            print "It's nonsense to have a group as its GroupMembers\n",
	          "... skipping $group as GroupMembers in $project\n";
	    next;
        }
        # fetching the user-string of the group
        ($a,$a,$a,$group_users)=getgrnam("$group");
        if (not defined $group_users){
            # group nonexisting
	    print "Coldn't find $group, ... skipping $group\n";
            next;
        } else {
            # group exists
            @users_pri=&get_user_adminclass($group);
            @users_sec=split(/ /, $group_users);
        }

        @group_users = (@users_pri,@users_sec);
        if($Conf::log_level>=2){
            print "       Primary Users in group $group: @users_pri\n";
            print "       Secondary Users in group $group: @users_sec\n";
            print "     All users in group $group: @group_users\n";
        }
        foreach my $user (@group_users){        
           if (not exists $users{$user}){
       	      $users{$user}=$group;
           } else {
           }
        }
    }
    return %users;
}






=pod

=item I<create_userlist(logins,classes,pupil,rooms,workstations,check)>

Creates a ascibetical list of users, that are specified with the
parameters. The parameters are:

logins:       commaseperated list of logins

classes:      commaseperated list of AdminClasses, (can also be lehrer)

pupil:        add the list of all pupils (1), or not (0)

rooms:        commaseperated list of rooms

workstations: add the list of all workstations (1), or not (0)

check:        check (1) every loginname if it is a valid pupil,teacher 

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
          @users=&get_user_adminclass($class);
          push @userlist, @users;
       }
     }

     if ($pupil==1) {
        my @users=();
        @users=&get_pupils_school();
        push @userlist, @users;
     }

     if ($rooms ne "") {
        my @users=();
        my (@roomlist)=split(/,/,$rooms);
        foreach my $room (@roomlist){
           @users=&get_workstations_room($room);
           push @userlist, @users;
        }
      }

      if ($ws==1) {
        my @users=();
        @users=&get_workstations_school();
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

=item I<get_ml_users()>

Returns an hash with ALL ml login names. This includes:
  - pupil, teachers (sophomorix database)
  - workstations

The value is one of teacher, pupil or workstation

=cut

sub get_ml_users {
    my @pwliste=();
    my %ml_hash=();
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis
       if ($pwliste[7]=~/^$DevelConf::homedir_pupil/) {
	   $ml_hash{$pwliste[0]}="pupil";
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

=head2 Working with MyClasses (querying, adding, removing, ...)

=over 4

=item I<get_my_adminclasses(Login)>

Returns an ascibetical list of adminclasses in which the user Login
has added herself. If a class exists multiple times, it is retured once.

=cut

sub get_my_adminclasses {
    my ($login) = @_;
    my @classes=();
    my %classes=();
    my $file=&provide_my_class_file($login);
    open(MYCLASS, "<$file");
    while(<MYCLASS>){
        chomp();
        $classes{$_}="";
    }
    while (my ($key) = each %classes){
        push @classes, $key;
    }
    close(MYCLASS);
    @classes = sort @classes;
    return @classes;
}



=pod

=item I<add_my_adminclass(Login,AdminClass)>

Adds AdminClass to the classes of the user Login.

=cut

sub add_my_adminclass {
    my ($login,$class) = @_;
    my $file=&provide_my_class_file($login);
    my @list=&get_my_adminclasses($login);
    my $seen=0;
    my $valid=0;

    # check if $class is really a class
    my @valid_classes=get_adminclasses_school();
    foreach my $item (@valid_classes){
	if ($item eq $class){
	    $valid=1;
        }
    }
    if ($valid==0){
        print "$class is not a valid AdminClass\n";
	return 0;
    }

    # add class to the list of classes if not already there
    foreach my $item (@list){
	if ($item eq $class){
	    $seen=1;
        }
    }
    if ($seen==0){
	push @list, $class;
    }
    @list = sort @list;

    # write the list to the file
    open(MYCLASS, ">$file");
    foreach my $item (@list){
	print MYCLASS "$item"."\n";
    }
    close(MYCLASS);
    #system("$file.tmp $file");
    return @list;
}



# zurückgeben, und falls inexistent anlegen
sub provide_my_class_file {
    my ($login) = @_;
    my ($home)=${DevelConf::homedir_teacher}."/".$login;
    my ($dotdir)=$home."/.sophomorix";
    my ($file)=$dotdir."/MyAdminClasses";
    # create the dotfile-stuff
    if (not -e $dotdir){
	mkdir $dotdir;
        defined(my $uid = getpwnam $login) or die "bad user";
        chown $uid, 0, $dotdir;
    }
    if (not -e $file){
	system("touch $file");
        defined(my $uid = getpwnam $login) or die "bad user";
        chown $uid, 0, $file;
    }
    if($Conf::log_level>=3){
       print "Extracting data from $file\n";
   }
    return $file;
}

=pod

=item I<remove_my_adminclass(Login,AdminClass)>

Removes AdminClass from the classes of the user Login.

=cut

sub remove_my_adminclass {
    my ($login,$class) = @_;
    my $file=&provide_my_class_file($login);
    my @list=&get_my_adminclasses($login);
    my @new_list=();
    foreach my $item (@list){
	if ($item ne $class){
	    push @new_list, $item;
        }
    }
    # write new list to file
    open(MYCLASS, ">$file");
    foreach my $item (@new_list){
	print MYCLASS "$item"."\n";
    }
    close(MYCLASS);
    return @new_list;
}









# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
