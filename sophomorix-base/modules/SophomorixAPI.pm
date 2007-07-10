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
            );


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
        $classes,$add_class_teachers,
        $projects,$add_project_admins,
        $student,
        $rooms,$ws,$administrators,$check) = @_;
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

    # add my adminclass to database
    &addadmin_to_adminclass($login,$class);

    # create link
    &Sophomorix::SophomorixBase::create_share_link($login,
         $class,$class,"adminclass");

    # join group in pg
    &pg_adduser($login,$class);
    # join group in ldap
    &auth_adduser_to_project($login,$class);

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

    # remove admin     
    &deleteadmin_from_adminclass($login,$class);

    # remove secondary membership in pg
    &deleteuser_from_project($login,$class,0,1);
    # remove secondary membership in ldap
    &auth_deleteuser_from_project($login,$class);

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
