#!/usr/bin/perl -w
# $Id$
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
             add_my_adminclass
             remove_my_adminclass
             fetch_error_string
            );


=head1 Documentation of SophomorixAPI.pm


B<sophomorix> is a user administration tool for a school server. It
uses a file with all students dumped from a school administration
software. The users in this file are synchronised into a linux system
running postgres, ldap and samba.

Using SophomorixAPI.pm in perl scripts gives acces to the data of
sophomorix without knowing the internals (sophomorixologie). 

Using SophomorixAPI.pm will avoid breaking your scripts when
sophomorix internals change.

A very good example, when you should use SophomorixAPI.pm is writing
webmin modules for sophomorix. Another example is the B<Schulkonsole> of paedML.

=head2 SYNOPSIS

   # This is for access to configuration variables
   use Sophomorix::SophomorixConfig;

   # This is for access of functions in SophomorixAPI
   use Sophomorix::SophomorixAPI;
   
   # example: access variables in sophomorix.conf    
   my $school = $Conf::schul_name;
 
   # example: access variables in sophomorix-devel.conf    
   my $smb_home = $DevelConf::homedir_samba_netlogon;

   # example: access variables in sophomorix-lang.NAME
   # where NAME is one of de, en, ...    
   my $directory = $Language::collect_dir;


Note: If you want to use funcions you have to use BOTH packages
(SophomorixConfig AND SophomorixAPI, in this order)


=head2 FUNCTIONS

=head2 General Functions

=over 4

=item I<$err_string = fetch_error_string(number,type)>

Returns the error string for a given integer return value. 

The following types exist:

type=1  : return console error string

type=2  : return schulkonsole error string (standard)

=cut



sub fetch_error_string {
    my ($number,$type) = @_;
    # type: 0 empty
    #       1 console 
    #       2 schuko  (standard)
    if (not defined $type){
        $type=2;
    }
    my $string = "Unknown Error in errors.lang\n";
    open(ERRFILE, "<${DevelConf::lang_err_file}");
    while (<ERRFILE>) {
        chomp();
        if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
        if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
        my ($ret,$console,$schuko) = split(/::/);
        if ($ret==$number){
            if ($type==2){
		$string=$schuko;
                last;
            } elsif ($type==1){
                $string=$console;
                last;
            }
        }
    }
    close(ERRFILE);
    return $string;
}





=pod



=head2 Query users or groups of users 

=over 4

=item I<@list = fetchstudents_from_school()>

Returns an asciibetical list of all students of the school. No teachers
are returned

=cut


# replaces get_students_school
sub fetchstudents_from_school {
    my @students=();
    my $dbh=&Sophomorix::SophomorixPgLdap::db_connect();
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uid 
                             FROM userdata 
                             WHERE (gid!='$DevelConf::teacher' 
                               AND homedirectory LIKE '/home/students%') 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($uidnumber)=@$row;
       push @students, $uidnumber;
    }

    &Sophomorix::SophomorixPgLdap::db_disconnect($dbh);
    return @students;

}



=pod

=I<@list = create_userlist(logins,classes,students,rooms,workstations,administrators,check)>

Creates a ascibetical list of users, that are specified with the
parameters. The parameters are:

logins:        comma seperated list of logins

classes:       comma seperated list of AdminClasses, (can also be teachers)

add_class_teachers: add teachers in this class (1) or not (0)

projects:       comma seperated list of projects

add_project_admins: add admins in this project (1) or not (0)

students:      add the list of all students (1), or not (0)

rooms:         comma seperated list of rooms

workstations:  add the list of all workstations (1), or not (0)

administrators: add the list of all administrators (1), or not (0)

check:         check (1) every loginname if it is a valid student,teacher 

               or workstation or not (0)

Option check makes this function very slow!

=cut



sub create_userlist {
    my @userlist=();
    my %logins=();
    my @unique_userlist=();
    my ($login,
        $classes,
        $add_class_teachers,
        $projects,
        $add_project_admins,
        $student,
        $rooms,
        $ws,
        $administrators,
        $check) = @_;
    if (not defined $login){$login=""}   
    if (not defined $classes){$classes=""}   
    if (not defined $add_class_teachers){$add_class_teachers=0}   
    if (not defined $projects){$projects=""}   
    if (not defined $add_project_admins){$add_project_admins=0}   
    if (not defined $student){$student=0}   
    if (not defined $rooms){$rooms=""}   
    if (not defined $ws){$ws=0}   
    if (not defined $administrators){$administrators=0}   
    if (not defined $check){$check=0}   

    # loginnames
    if ($login ne "") {
       my (@loginlist)=split(/,/,$login);
       push @userlist, @loginlist;
    }

    if ($classes ne "") {
       my @users=();
       my @admins=();
       my (@classlist)=split(/,/,$classes);
       foreach my $class (@classlist){
          @users=&fetchstudents_from_adminclass($class);
          push @userlist, @users;
          if ($add_class_teachers==1){
              @admins=&fetchadmins_from_adminclass($class);
              push @userlist, @admins;
          }
       }
     }


    if ($projects ne "") {
       my @users=();
       my @admins=();
       my (@projectlist)=split(/,/,$projects);
       foreach my $project (@projectlist){
          @users=&fetchusers_from_project($project);
          push @userlist, @users;
          if ($add_project_admins==1){
              @admins=&fetchadmins_from_project($project);
              push @userlist, @admins;
          }
       }
     }

     if ($student==1) {
        my @users=();
        @users=&fetchstudents_from_school();
        push @userlist, @users;
     }

     if ($rooms ne "") {
        my @users=();
        my (@roomlist)=split(/,/,$rooms);
        foreach my $room (@roomlist){
           @users=&fetchworkstations_from_room($room);
           push @userlist, @users;
        }
      }

      if ($ws==1) {
        my @users=();
        @users=&fetchworkstations_from_school();
        push @userlist, @users;
      }

      if ($administrators==1) {
        my @users=();
        @users=&fetchadministrators_from_school();
        push @userlist, @users;
      }

      # create userlist
      if ($check==1 and not $#userlist+1==0){
         %logins=&fetchusers_sophomorix();
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
                  print "INFO: $item is not a sophomorix ",
                        "user, skipping $item ...\n";
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

=item I<add_my_adminclass(Login,AdminClass)>

Adds the valid AdminClass to MyAdminClasses of the user Login.

=cut

sub add_my_adminclass {
    my ($login,$class) = @_;

    my ($type)=&pg_get_group_type($class);
    if ($type eq "hiddenclass"){
        print "\nYou cannot join $class ($class is of type hiddenclass)\n\n";
        return 0;
    }

    # add my adminclass to database
    &addadmin_to_adminclass($login,$class);

    # create link
    &Sophomorix::SophomorixBase::create_share_link($login,
         $class,$class,"adminclass");

    # join user (pg,ldap)
    &adduser_to_project($login,$class,0);

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

        # join user (pg,ldap)
        #&adduser_to_project($login,$subclass,0);

        # create dirs in tasks and collect
        &Sophomorix::SophomorixBase::create_share_directory($login,
            $subclass,$subclass,"subclass");
   }
   return 1;
}



=pod

=item I<remove_my_adminclass(Login,AdminClass)>

Removes AdminClass from the classes of the user Login and returns 1;.

If the class could not be removed (because it didn't exist in
MyAdminClasses), 0 is returned.

=cut

sub remove_my_adminclass {
    my ($login,$class) = @_;

    # remove admin     
    &deleteadmin_from_adminclass($login,$class);

    # remove secondary membership in pg
    &deleteuser_from_project($login,$class,0,1);
    # remove secondary membership in ldap
#    &auth_deleteuser_from_project($login,$class);

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

       # not needed is done before
        # join user (pg,ldap)
       #print "Remove $subclass\n"; 
       #&adduser_to_project($login,$subclass,0);
#       &deleteuser_from_project($login,$class,0,1);

        # remove dirs in tasks and collect
        &Sophomorix::SophomorixBase::remove_share_directory($login,
            $subclass,$subclass,"subclass");
   }
}








# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
