#!/usr/bin/perl -w
# $Id$ 
# Dieses Modul (SophomorixPgLdap) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

package Sophomorix::SophomorixPgLdap;
require Exporter;
@ISA =qw(Exporter);
@EXPORT = qw(show_modulename
             db_connect
             db_disconnect
             check_connections
             add_newuser_to_her_projects
             adduser_to_project
             addadmin_to_project
             addgroup_to_project
             addproject_to_project
             fetchinfo_from_project
             fetchusers_from_project
             fetchmembers_from_project
             fetchmembers_by_option_from_project
             fetchadmins_from_project
             fetchgroups_from_project
             fetchprojects_from_project
             deleteuser_from_project
             deleteadmin_from_project
             deletegroup_from_project
             deleteproject_from_project
             deleteuser_from_all_projects
             addadmin_to_adminclass
             deleteadmin_from_adminclass
             fetchstudents_from_adminclass
             fetchadmins_from_adminclass
             fetchusers_from_adminclass
             fetch_my_adminclasses
             fetchdata_from_account
             fetchnetexamplix_from_account
	     create_user_db_entry
             date_perl2pg
             date_pg2perl
             create_class_db_entry
             update_class_db_entry
             remove_class_db_entry
             pg_adduser
             pg_remove_all_secusers
             pg_get_group_list
             pg_get_group_type
             pg_get_group_members
             pg_get_adminclasses
             fetchadminclasses_from_school
             fetchsubclasses_from_school
             fetchprojects_from_school
             fetchrooms_from_school
             fetchclassrooms_from_school
             fetchworkstations_from_school
             fetchworkstations_from_room
             fetchadministrators_from_school
             fetchusers_sophomorix
             set_sophomorix_passwd
             user_deaktivieren
             user_reaktivieren
	     update_user_db_entry
	     remove_user_db_entry
             create_project
             remove_project
             get_sys_users
             forbidden_login_hash
             get_teach_in_sys_users
             get_print_data
             search_user
             backup_user_database
             get_first_password
             check_sophomorix_user
             show_project_list
             show_class_list
             show_class_teacher_list
             show_teacher_class_list
             fetch_used_subclasses
             show_subclass_list
             show_project
             dump_all_projects
             show_room_list
             get_smb_sid
             fetchquota_sum
             kill_user
             auth_passwd
             auth_useradd
             auth_groupadd
             auth_groupdel
             auth_usermove
             auth_killmove
             auth_disable
             auth_enable
             auth_deleteuser_from_all_projects
             auth_adduser_to_her_projects
             auth_adduser_to_project
             auth_deleteuser_from_project
             auth_firstnameupdate
             auth_lastnameupdate
             auth_gecosupdate
             auth_connect
             auth_disconnect
             fetch_ldap_pg_passwords
             dump_slapd_to_ldif
             add_slapd_from_ldif
             patch_ldif
);
# deprecated:             move_user_db_entry
#                         move_user_from_to


# ??????????
# here i dont need to say Sophomorix::SophomorixBase::titel
# as in SophomorixSYSFiles. Whats wrong?
use Sophomorix::SophomorixBase qw ( titel
                                    do_falls_nicht_testen
                                    provide_class_files
                                    provide_project_files
                                    get_user_history
                                    print_forward
                                    print_list_column
                                  );
use Crypt::SmbHash;
use Sophomorix::SophomorixAPI qw( 
                                  fetchstudents_from_school
                                );
use IMAP::Admin;


=head1 Documentation of SophomorixPgLdap.pm

=head2 FUNCTIONS


=cut


sub show_modulename {
#    if($Conf::log_level>=2){
       &Sophomorix::SophomorixBase::titel("DB-Backend-Module:   SophomorixPgLdap.pm");
#   }
}



# connect to sql database
sub db_connect {
    my ($raise_error) = @_;
    if (not defined $raise_error or $raise_error eq ""){
        $raise_error=1;
    }
    my $dbname="ldap";
    my $dbuser="postgres";
    # password not needed because of postgres configuration
    # in pg_hba.conf pg_ident.conf
    my $pass_saved="";
    # needs at UNIX sockets:   local all all  trust sameuser
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$dbuser","$pass_saved",
               { RaiseError => $raise_error, PrintError => 0, AutoCommit => 1 });
    if (defined $dbh){
    } else {
       print "   Could not connect to database with password $pass_saved!\n";
    }
    return $dbh
}


# connect to sql database
sub db_disconnect {
    my ($dbh) = @_;
    $dbh->disconnect();
}




sub check_connections {
    # check postgres and slapd. exit when they are not running
    # postgres
    my $dbname="ldap";
    my $dbuser="ldap";
    my $pass_saved="";
    # needs at UNIX sockets:   local all all  trust sameuser
    if($Conf::log_level>=3){
       print "   Checking postgres connection... \n";
    }
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$dbuser","$pass_saved",
              { RaiseError => 0, PrintError => 0}) or
       &Sophomorix::SophomorixBase::log_script_exit("No connection to postgresql!",
         1,1,0,@arguments);

    # ldap
    if($Conf::log_level>=3){
       print "   Checking ldap connection... \n";
    }
    my $ldap = Net::LDAP->new( '127.0.0.1' ) or 
       &Sophomorix::SophomorixBase::log_script_exit("No connection to sldapd!",
         1,1,0,@arguments);
}




##############################################################################
#                                                                            #
#  Functions for projects                                                    #
#                                                                            #
##############################################################################

sub fetchinfo_from_project {
    my ($project) = @_;
    unless ($project =~ m/^p\_/) { 
       $project="p_".$project;
    }
    my $dbh=&db_connect();
    my ($longname,$addquota,$add_mail_quota,$status,$join,
        $time,$max_members,$mailalias,
        $maillist,$id,$type,$schooltype,$department,
        $creationdate,$enddate,$tolerationdate,$deactivationdate
        ) = $dbh->selectrow_array( "SELECT longname,addquota,
           addmailquota,sophomorixstatus,joinable,creationdate,maxmembers,
           mailalias,maillist,id,type,schooltype,department,
           creationdate,enddate,tolerationdate,deactivationdate
                          FROM projectdata 
                          WHERE gid='$project'");
    &db_disconnect($dbh);
    if (not defined $schooltype){
        $schooltype="";
    }
    if (not defined $type){
        $type="";
    }
    if (not defined $department){
        $department="";
    }
    if (not defined $enddate){
        $enddate="";
    }
    if (not defined $tolerationdate){
        $tolerationdate="";
    }
    if (not defined $deactivationdate){
        $deactivationdate="";
    }

    return ($longname,$addquota,$add_mail_quota,
            $status,$join,$time,$max_members,$mailalias,$maillist,
            $id,$type,$schooltype,$department,
            $creationdate,$enddate,$tolerationdate,$deactivationdate);    
}



sub fetchusers_from_project {
    # return a list of uid of ALL users (members AND admins) of the given project
    # linux: which users are secondary members of group
    my ($group) = @_;
    unless ($group =~ m/^p\_/) { 
       $group="p_".$group;
    }
    my @userlist=();
    my $dbh=&db_connect();
    # fetching gid
    my ($gidnumber_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$group'
                                        ");
    if (not defined $gidnumber_sys){
        print "WARNING: $group not found\n";
	return @userlist;
        exit;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT memberuidnumber 
                            FROM groups_users 
                            WHERE gidnumber=$gidnumber_sys 
                           " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($uidnumber)=@$row;
       # fetching uid
       my ($uid_sys)= $dbh->selectrow_array( "SELECT uid 
                                         FROM posix_account 
                                         WHERE uidnumber=$uidnumber");
       push @userlist, $uid_sys;
    }
    &db_disconnect($dbh);
    return @userlist;
}



sub fetchmembers_by_option_from_project {
    # return a list of uid of members that were added by_option
    my ($project) = @_;
    unless ($project =~ m/^p\_/) { 
       $project="p_".$project;
    }
    my %members=();
    my @userlist=();
    my $dbh=&db_connect();
    # fetching list of uidnumbers
    my $sth= $dbh->prepare( "SELECT memberuidnumber 
                             FROM projects_members 
                             WHERE projectid=(
                               SELECT id from projectdata 
                               WHERE gid='$project')
                            ");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       my ($memberuidnumber)=@$row;
       my ($uid_sys)= $dbh->selectrow_array( "SELECT uid from userdata 
                                              WHERE 
                                              uidnumber='$memberuidnumber'
                                             ");
        push @userlist, $uid_sys;
    }
    return @userlist;
}



sub fetchmembers_from_project {
    # return a list of uid of members (no admins!) of the given project 
    my ($group) = @_;
    unless ($group =~ m/^p\_/) { 
       $group="p_".$group;
    }
    my %members=();
    my @userlist=();
    my $dbh=&db_connect();
    # fetching gid
    my ($gidnumber_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$group'
                                        ");
    if (not defined $gidnumber_sys){
        print "WARNING: $group not found\n";
	return @userlist;
        exit;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT memberuidnumber 
                            FROM groups_users 
                            WHERE gidnumber=$gidnumber_sys 
                           " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($uidnumber)=@$row;
       # fetching uid
       my ($uid_sys)= $dbh->selectrow_array( "SELECT uid 
                                         FROM posix_account 
                                         WHERE uidnumber=$uidnumber");
       $members{$uid_sys}="member";
    }
    &db_disconnect($dbh);
    my @admins=&fetchadmins_from_project($group);
    foreach my $admin (@admins){
        delete($members{$admin})
    }
    while(my ($user, $value) = each(%members)) {
        # do something with $key and $value
        push @userlist,$user;
    }
    @userlist = sort @userlist;

    return @userlist;
}




sub fetchadmins_from_project {
    # return a list of uid of admins of the given project
    my ($group) = @_;
    unless ($group =~ m/^p\_/) { 
       $group="p_".$group;
    }

    my @userlist=();
    my $dbh=&db_connect();
 
    # fetching project_id
    my ($pro_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$group'");
    if (not defined $pro_id_sys){
        print "WARNING: $group not found\n";
	return @userlist;
        exit;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uidnumber 
                             FROM projects_admins 
                             WHERE projectid=$pro_id_sys 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($uidnumber)=@$row;
       # fetching uid
       my ($uid_sys)= $dbh->selectrow_array( "SELECT uid 
                                         FROM posix_account 
                                         WHERE uidnumber=$uidnumber");
       push @userlist, $uid_sys;
    }
    &db_disconnect($dbh);
    return @userlist;
}



sub fetchgroups_from_project {
    # return a list of gid of groups of the given project
    my ($project) = @_;
    unless ($project =~ m/^p\_/) { 
       $project="p_".$project;
    }
    my @grouplist=();
    my $dbh=&db_connect();
    # fetching id from project  
    my ($pro_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
    if (not defined $pro_id_sys){
        print "WARNING: $project not found\n";
	return @userlist;
        exit;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT membergid 
                             FROM project_groups 
                             WHERE projectid=$pro_id_sys 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($member_gidnumber)=@$row;
       # fetching gid
       my ($gid_sys)= $dbh->selectrow_array( "SELECT gid 
                                         FROM groups 
                                         WHERE gidnumber=$member_gidnumber");
       push @grouplist, $gid_sys;
    }
    &db_disconnect($dbh);
    return @grouplist;
}



sub fetchprojects_from_project {
    # return a list of member projects of the given project
    my ($group) = @_;
    unless ($group =~ m/^p\_/) { 
       $group="p_".$group;
    }
    my @project_list=();
    my $dbh=&db_connect();
     # fetching project_id
    my ($pro_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$group'");
    if (not defined $pro_id_sys){
        print "WARNING: $group not found\n";
	return @userlist;
        exit;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT memberprojectid 
                            FROM projects_memberprojects 
                            WHERE projectid=$pro_id_sys 
                           " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($memberpro_id)=@$row;
       # fetching name of memberproject
       my ($id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM project_details 
                                         WHERE id=$memberpro_id");
       my ($m_project)= $dbh->selectrow_array( "SELECT gid 
                                         FROM groups 
                                         WHERE id='$memberpro_id'");

       push @project_list, $m_project;
    }
    &db_disconnect($dbh);
    return @project_list;
}



sub deleteuser_from_project {
    # remove user from its secondary membership in project(group)
    # (adding a user is pg_adduser)
    # adminclass = 0 : use groupname  with p_ in the beginning ($project)
    # adminclass = 1 : use groupname as given
    my ($user,$project,$by_option,$adminclass)=@_;
    if (not defined $adminclass){
        $adminclass=0;
    }
    unless ($project =~ m/^p\_/) { 
	if ($adminclass==0){
            $project="p_".$project;
        }
    }
    if (not defined $by_option){
        $by_option=0;
    }
    my $dbh=&db_connect();
    # fetching gidnumber
    my ($gidnumber_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");

    if (defined $gidnumber_sys and defined $uidnumber_sys){
        print "   Removing user $user($uidnumber_sys) ",
              "from $project($gidnumber_sys) \n";
        my $sql="DELETE FROM groups_users 
                 WHERE (memberuidnumber=$uidnumber_sys 
                 AND gidnumber=$gidnumber_sys) 
                ";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);

        # removing user from secondary group
        &auth_deleteuser_from_project($user,$project);

        # remove track of members by option
        if ($by_option==1){
           # fetching project id
           my ($project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
           # check for existance
           my ($result)= $dbh->selectrow_array( "SELECT memberuidnumber 
                                         FROM projects_members 
                                         WHERE projectid='$project_id_sys'");
           if (defined $result){
               print "   Removing user $user($uidnumber_sys) ",
                     "from projects_members \n";
               $sql="DELETE FROM projects_members
                     WHERE (memberuidnumber=$uidnumber_sys 
                     AND projectid=$project_id_sys) 
                    ";	
               if($Conf::log_level>=3){
                   print "\nSQL: $sql\n";
               }
               $dbh->do($sql);
           }
        }
    } else {
        if (not defined $uidnumber_sys){
            print "   NOT removing user $user from project ",
                  "$group: user doesn't exist\n";
        } elsif (not defined $gidnumber_sys){
            print "   NOT removing user $user from project ",
                  "$group: group doesn't exist\n";
        }
    }
    &db_disconnect($dbh);
}


sub deleteadmin_from_project {
    # remove admin from project
    my ($user,$project)=@_;
    unless ($project =~ m/^p\_/) { 
       $project="p_".$project;
    }
    my $dbh=&db_connect();
    # fetching id
    my ($project_id_sys)= $dbh->selectrow_array( "SELECT id 

                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");
    if (defined $uidnumber_sys and defined $project_id_sys){
        print "   Removing admin $user($uidnumber_sys) from ",
              "$project($project_id_sys) \n";
        my $sql="DELETE FROM projects_admins 
                 WHERE (uidnumber=$uidnumber_sys AND projectid=$project_id_sys) 
                ";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
        # remove dirs in tasks and collect
        my ($project_longname)=&fetchinfo_from_project($project);
        &Sophomorix::SophomorixBase::remove_share_directory($user,
             $project,$project_longname,"project");
    } else {
        if (not defined $uidnumber_sys){
           print "   User $user does not exist, doing nothing. \n";
        }
        if (not defined $project_id_sys){
           print "   Project $project does not exist, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
    # remove admin also as a user
    &deleteuser_from_project($user,$project,0);
}


sub deletegroup_from_project {
    # remove group from project
    my ($group,$project)=@_;
    unless ($project =~ m/^p\_/) { 
       $project="p_".$project;
    }
    my $dbh=&db_connect();
    # fetching project_id
    my ($pro_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching gidnumber of group
    my ($group_gidnumber)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$group'");
    print "   Removing group $group($group_gidnumber) from ",
          "$project(id=$pro_id_sys) \n";
    my $sql="DELETE FROM project_groups 
             WHERE (projectid=$pro_id_sys AND membergid=$group_gidnumber) 
             ";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
    &db_disconnect($dbh);

}



sub deleteproject_from_project {
    # remove memberproject from project
    my ($m_project,$project)=@_;
    unless ($project =~ m/^p\_/) { 
       $project="p_".$project;
    }
    my $dbh=&db_connect();
    # fetching project id
    my ($project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching m_project id
    my ($m_project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$m_project'");
    if (defined $m_project_id_sys and defined $project_id_sys){
       print "   Removing Project $m_project($m_project_id_sys) from ",
             "$project($project_id_sys) \n";
       my $sql="DELETE FROM projects_memberprojects 
                WHERE (memberprojectid=$m_project_id_sys 
                  AND projectid=$project_id_sys) 
               ";	
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       $dbh->do($sql);
    } else {
        if (not defined $m_project_id_sys){
           print "   MemberProject $m_project_id_sys does not exist,",
                 " doing nothing. \n";
        }
        if (not defined $project_id_sys){
           print "   Project $project does not exist, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
}



sub deleteuser_from_all_projects {
    # remove user from all secondary project-memberships(group-membership)
    # if admin is
    my ($user,$admin)=@_;
    my $dbh=&db_connect();
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");
    if (not defined $uidnumber_sys){
	print "Could not delete user from all projects\n";
	print "user $user nonexisting\n";
        return 0;
    }
    print "   Removing user $user($uidnumber_sys) from all projects \n";
    my $sql="DELETE FROM groups_users 
             WHERE memberuidnumber=$uidnumber_sys ";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);

    $sql="DELETE FROM projects_members 
             WHERE memberuidnumber=$uidnumber_sys ";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);

    if (not defined $admin){
       print "   Removing admin $user($uidnumber_sys) from all projects \n";
       $sql="DELETE FROM projects_admins 
             WHERE uidnumber=$uidnumber_sys ";	
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       $dbh->do($sql);
    }
    &db_disconnect($dbh);

    # delete user from project in auth system
    &auth_deleteuser_from_all_projects($user);
}







# add a new user to projects she is in because of her adminclass
sub add_newuser_to_her_projects {
    my ($login,$adminclass) = @_;
    my @memberships=();
    print "   New Group of $login is: $adminclass\n";    
    my $dbh=&db_connect();
    # fetching uidnumber
    my ($uidnumber)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM userdata 
                                         WHERE uid='$login'
                                        ");
    if (not defined $uidnumber){
        print "WARNING: Cannot add user $login to projects\n";
        print "         No uidnumber found!\n";
        exit;
    }    
    # fetching gidnumber of adminclass
    my $sth= $dbh->prepare( "SELECT projectid
                             FROM project_groups 
                             WHERE membergid=( SELECT gidnumber 
                                               FROM groups 
                                               WHERE gid='$adminclass') 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($pro_id)=@$row;
       # fetching gid
       my ($gid_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE id=$pro_id");
       print "$adminclass is member of Project with ID ",
             "$pro_id(gidnumber=$gid_sys) \n";
       push @memberships, $gid_sys;

       # look if project is member in other projects
       my $sth2= $dbh->prepare( "SELECT projectid
                                 FROM projects_memberprojects 
                                 WHERE memberprojectid=$pro_id
                            " );
       $sth2->execute();
       my $array_ref2 = $sth2->fetchall_arrayref();
       foreach my $row (@$array_ref2){
           my ($pro_id2)=@$row;
           # fetching gid
           my ($gid_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                                  FROM groups 
                                                  WHERE id=$pro_id2
                                                 ");
           print "Project with ID $pro_id is member of Project with ID ",
                 "$pro_id2(gidnumber=$gid_sys) \n";

           push @memberships, $gid_sys;
       }
    }

    # Result
    @memberships = sort @memberships;

    # Do it!
    print "   Adding user $login to the projects ...\n";
    foreach my $group_gidnumber (@memberships){
        # check if it exists already.
        my ($gid,$uid)= $dbh->selectrow_array( "SELECT gidnumber,memberuidnumber 
                                         FROM groups_users 
                                         WHERE (gidnumber=$group_gidnumber
                                         AND memberuidnumber=$uidnumber)
                                        ");
        if (defined $gid and defined $uid){
            print "    Not adding $login($uidnumber) to group $group_gidnumber",
                  " (exists already)\n";
        } else {
            print "    Adding $login($uidnumber) to group $group_gidnumber \n";
            my $sql="INSERT INTO groups_users
                    (gidnumber,memberuidnumber)
	             VALUES
	            ($group_gidnumber,'$uidnumber')";	
            if($Conf::log_level>=3){
                print "\nSQL: $sql\n";
            }
            $dbh->do($sql);
            my ($project)= $dbh->selectrow_array( "SELECT gid 
                                                  FROM groups 
                                                  WHERE gidnumber=$group_gidnumber
                                                 ");

            my ($longname)= $dbh->selectrow_array( "SELECT longname 
                                                  FROM projectdata 
                                                  WHERE gidnumber=$group_gidnumber
                                                 ");
            # create a link
            &Sophomorix::SophomorixBase::create_share_link($login,
                                                $project,$longname);
            # create directories 
            &Sophomorix::SophomorixBase::create_share_directory($login,
                                                $project,$longname);
        }
    }
    print "... done!\n";
    &db_disconnect($dbh);

    # adding user in auth system
    my $group_string=join(",",@memberships);
    &auth_adduser_to_her_projects($login,$group_string);    
}







sub adduser_to_project {
    # add a user as secondary membership to a project(group)
    my ($user,$project,$by_option)=@_;
    if (not defined $by_option){
        $by_option=0;
    }
    my $dbh=&db_connect();
    # fetching gidnumber
    my ($gidnumber_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");

    if (defined $uidnumber_sys and defined $gidnumber_sys){
        print "   Adding user $user($uidnumber_sys) to $project($gidnumber_sys) \n";
        my $sql="INSERT INTO groups_users
                (gidnumber,memberuidnumber)
	        VALUES
	        ($gidnumber_sys,'$uidnumber_sys')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);

        # adding user to secondary group
        &auth_adduser_to_project($user,$project);

        # keep track of members by option
        if ($by_option==1){
            &adduser_by_option_to_project($user,$project);
        }
    } else {
        if (not defined $uidnumber_sys){
           print "   User $user does not exist, doing nothing. \n";
        }
        if (not defined $gidnumber_sys){
           print "   Group $project does not exist, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
}


sub adduser_by_option_to_project{
    # add user in the projects_members table
    my ($user,$project)=@_;

    my $dbh=&db_connect();
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");
    # fetching project id
    my ($project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                      FROM groups 
                                      WHERE gid='$project'");
    print "   Adding user $user($uidnumber_sys) to projects_members \n";
    $sql="INSERT INTO projects_members
          (projectid,memberuidnumber)
	  VALUES
	  ($project_id_sys,'$uidnumber_sys')";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
    &db_disconnect($dbh);
}




sub addadmin_to_project {
    # add an admin to a project(group)
    my ($user,$project)=@_;
    my $dbh=&db_connect();
    # fetching gidnumber
    my ($project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");

    if (defined $uidnumber_sys and defined $project_id_sys){
        print "   Adding user $user($uidnumber_sys) ", 
              "to $project(id=$project_id_sys) as admin\n";
        my $sql="INSERT INTO projects_admins
                (projectid,uidnumber)
	        VALUES
	        ($project_id_sys,'$uidnumber_sys')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);

        # create dirs in tasks and collect
        my ($project_longname)=&fetchinfo_from_project($project);
        &Sophomorix::SophomorixBase::create_share_directory($user,
             $project,$project_longname,"project");
    } else {
        if (not defined $uidnumber_sys){
           print "   User $user does not exist, doing nothing. \n";
        }
        if (not defined $project_id_sys){
           print "   Project $project does not exist, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
}



sub addgroup_to_project {
    # add a group to a project(group)
    my ($group,$project)=@_;
    my $dbh=&db_connect();
    # fetching project_id
    my ($pro_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
    # is $group really a adminclass
    my ($group_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM classdata 
                                         WHERE (id=(SELECT id 
                                         FROM groups 
                                         WHERE gid='$group')
                                         AND type='adminclass')");
    # fetching gidnumber of group
    my ($group_gidnumber)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$group'");
    if (defined $group_gidnumber and defined $pro_id_sys 
                                 and defined $group_id_sys){
        print "   Adding group $group($group_gidnumber) ", 
              "to $project(id=$pro_id_sys)\n";
        my $sql="INSERT INTO project_groups
                (projectid,membergid)
	        VALUES
	        ($pro_id_sys,$group_gidnumber)";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    } else {
        if (not defined $group_gidnumber){
           print "   Group $group does not exist, doing nothing. \n";
        }
        if (not defined $pro_id_sys){
           print "   Project $project does not exist, doing nothing. \n";
        }
        if (not defined $group_id_sys){
           print "   Group $group is not a primary group, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
}





sub addproject_to_project {
    # add a project to a project(group)
    my ($m_project,$project)=@_;
    my $dbh=&db_connect();
    # fetching project id
    my ($project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$project'");
    # fetching m_project id
    my ($m_project_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$m_project'");
    my $pro_id;
    if (defined $m_project_id_sys){
      # is $m_project really a project
      ($pro_id)= $dbh->selectrow_array( "SELECT id 
                                         FROM classdata 
                                         WHERE (id='$m_project_id_sys'
                                         AND type='project')");
    }

    if (defined $m_project_id_sys and defined $project_id_sys
                                  and defined $pro_id){
        print "   Adding project $m_project(id=$m_project_id_sys) ", 
              "to $project(id=$project_id_sys)\n";
        my $sql="INSERT INTO projects_memberprojects
                (projectid,memberprojectid)
	        VALUES
	        ($project_id_sys,'$m_project_id_sys')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    } else {
        if (not defined $m_project_id_sys){
           print "   MemberProject $m_project does not exist,",
                 " doing nothing. \n";
        }
        if (not defined $project_id_sys){
           print "   Project $project does not exist, doing nothing. \n";
        }
        if (not defined $pro_id){
           print "   $m_project is not a project, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
}



##############################################################################
#                                                                            #
#  Functions for adminclasses                                                #
#                                                                            #
##############################################################################

sub addadmin_to_adminclass {
    # add an admin to a adminclass(group)
    my ($user,$adminclass)=@_;
    my $dbh=&db_connect();
    # fetching id
    my ($adminclass_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$adminclass'");
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");

    if (defined $uidnumber_sys and defined $adminclass_id_sys){
        # trying to fetch  old entry
        my ($old_entry)= $dbh->selectrow_array( "SELECT uidnumber 
                                     FROM classes_admins 
                                     WHERE (uidnumber=$uidnumber_sys
                                       AND adminclassid=$adminclass_id_sys)");
        # adding only if not defined already
        if (not defined $old_entry){                
            print "   Adding user $user($uidnumber_sys) ", 
                  "to $adminclass(id=$adminclass_id_sys) as admin\n";
            my $sql="INSERT INTO classes_admins
                     (adminclassid,uidnumber)
	             VALUES
	             ($adminclass_id_sys,'$uidnumber_sys')";	
            if($Conf::log_level>=3){
                print "\nSQL: $sql\n";
            }
            $dbh->do($sql);
        } else {
            print "   User $user($uidnumber_sys) is in ", 
                  "$adminclass(id=$adminclass_id_sys) already\n";
        }
    } else {
        if (not defined $uidnumber_sys){
           print "   User $user does not exist, doing nothing. \n";
        }
        if (not defined $adminclass_id_sys){
           print "   Adminclass $adminclass does not exist, doing nothing. \n";
        }
    }
    &db_disconnect($dbh);
}




sub deleteadmin_from_adminclass {
    # remove admin from adminclass
    my ($user,$adminclass)=@_;
    my $dbh=&db_connect();
    # fetching id
    my ($adminclass_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$adminclass'");
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");

    if (defined $adminclass_id_sys and defined $uidnumber_sys){
        print "   Removing admin $user($uidnumber_sys) from ",
              "$adminclass($adminclass_id_sys) \n";
        my $sql="DELETE FROM classes_admins 
                 WHERE (uidnumber=$uidnumber_sys 
                   AND adminclassid=$adminclass_id_sys) 
                ";	
        if($Conf::log_level>=3){
            print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    } else {
        if (not defined $uidnumber_sys){
            print "   NOT removing user $user from class ",
                  "$adminclass: user doesn't exist\n";
        } elsif (not defined $gidnumber_sys){
            print "   NOT removing user $user from class ",
                  "$adminclass: adminclass doesn't exist\n";
        }
    }
    &db_disconnect($dbh);
}



sub fetchstudents_from_adminclass {
    # only students
    my ($class) = @_;
    my @userliste=();
    my $dbh=&db_connect();
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uid  
                             FROM userdata
                             WHERE gid='$class'
                             ORDER BY uid" );
       $sth->execute();
    my $i=0;
    my $array_ref = $sth->fetchall_arrayref();
    foreach ( @{ $array_ref } ) {
       push @userliste, ${$array_ref}[$i][0];
       $i++;
    }
    return @userliste;
}




sub fetchadmins_from_adminclass {
    # return a list of uid of admins of the given adminclass
    my ($group) = @_;
    my @userlist=();
    my $dbh=&db_connect();
 
    # fetching class_id
    my ($class_id_sys)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$group'");
    if (not defined $class_id_sys){
        print "WARNING: $group not found\n";
	return @userlist;
        exit;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uidnumber 
                             FROM classes_admins 
                             WHERE adminclassid=$class_id_sys 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($uidnumber)=@$row;
       # fetching uid
       my ($uid_sys)= $dbh->selectrow_array( "SELECT uid 
                                         FROM posix_account 
                                         WHERE uidnumber=$uidnumber");
       if (defined $uid_sys){
           push @userlist, $uid_sys;
       }
    }
    &db_disconnect($dbh);
    return @userlist;
}



sub fetchusers_from_adminclass {
    # return a list of 
    my ($group) = @_;
    my @user=&fetchstudents_from_adminclass($group);
    my @teacher=&fetchadmins_from_adminclass($group);
    my @all_users = ( @teacher, @user );
    return @all_users;
}






sub fetch_my_adminclasses {
    # return a list of adminclasses from a teacher
    my ($user) = @_;
    my @userlist=();
    my $dbh=&db_connect();
 
    # fetching uidnumber
    my ($uidnumber_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");


    if (not defined $uidnumber_sys){
        print "ERROR: Couldn't find user $user\n";
	return @userlist;
    }
    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT adminclassid
                             FROM classes_admins 
                             WHERE uidnumber=$uidnumber_sys 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       # split the array, to give better names
       my ($adminclass_id)=@$row;
       # fetching gid
       my ($gid_sys)= $dbh->selectrow_array( "SELECT gid 
                                         FROM groups 
                                         WHERE id=$adminclass_id");
       push @userlist, $gid_sys;
    }
    &db_disconnect($dbh);
    return @userlist;
}






##############################################################################
#                                                                            #
#  Functions for users                                                       #
#                                                                            #
##############################################################################


sub fetchdata_from_account {
    my ($login) = @_;
    my $dbh=&db_connect();
    my ($home,
        $group,
        $gecos,
        $uidnumber,
        $sambahomepath,
        $firstpassword,
       )= $dbh->selectrow_array( "SELECT homedirectory,gid,gecos,uidnumber,
                                         sambahomepath,firstpassword 
                                         FROM userdata 
                                         WHERE uid='$login'
                                        ");
    &db_disconnect($dbh);
    if (defined $home){
        if ($home=~/^$DevelConf::homedir_pupil\//){
            $type="student";
        } elsif ($group  eq ${DevelConf::teacher}){
	    $type="teacher";
        } elsif ($home=~/^$DevelConf::homedir_ws\//){
            $type="examaccount";
        } elsif ($home=~/\/dev\/null/){
            $type="domcomp";
        } elsif ($home=~/^$DevelConf::attic\//){
            $type="attic";
        } elsif ($home=~/^$DevelConf::homedir_all_admins\//){
            $type="administrator";
        } else {
            $type="none";
        }
        return ($home,$type,$gecos,$group,$uidnumber,$sambahomepath,
                $firstpassword);
    } else {
        return ("","","","",-1,"","");
    }
}




sub fetchnetexamplix_from_account {
    my ($login) = @_;
    my $dbh=&db_connect();
    my ($surname,
        $firstname,
        $birthday,
        $birthcity,
        $group,
        $uidnumber,
       )= $dbh->selectrow_array( "SELECT surname,firstname,birthday,
                                         birthcity,
                                         gid,uidnumber
                                         FROM userdata 
                                         WHERE uid='$login'
                                        ");
    &db_disconnect($dbh);

    if (not defined $birthcity){
        $birthcity="";
    }
    if ($birthcity==0){
        $birthcity="";
    }

    $birthday_pl = &date_pg2perl($birthday);


    if (defined $group){
        my $line=$surname.", ".$firstname.":".
                 $birthday_pl.":".
                 $birthcity.":".
                 $group.":".
                 $uidnumber.":";
        return ($line);
    } else {
        return ("");
    }
}





# adds a user to the user database
sub create_user_db_entry {
    my $sql="";
    # prepare data
    my $today=`date +%d.%m.%Y`;
    chomp($today);
    my $today_pg=&date_perl2pg($today);
    my $gecos;
    my ($nachname,
       $vorname,
       $birthday_perl,
       $admin_class,
       $login,
       $pass,
       $sh,
       $quota,
       $unid,
       $unix_epoc,
       $pg_timestamp,
       $sophomorix_status,
       $id_force,
       $homedir_force,
       $gecos_force,
       $type) = @_;

    my $gidnumber;
    my $uidnumber_auth;
    my $sambapwdmustchange;
    my $servername=`hostname -s`;
    chomp($servername);
    my $smb_homepath;
    my $smb_ldap_homepath;
    my $smb_homedrive;
    my $smb_acctflags;
    my $homedir="";

    if (not defined $mailquota){
       $mailquota=-1;
    }
    if (not defined $pg_timestamp){
       $pg_timestamp=$today_pg;
    }
    if (not defined $sophomorix_status){
       $sophomorix_status="U";
    }
    if ($sophomorix_status eq ""){
       $sophomorix_status="U";
    }
    if (not defined $gecos_force or $gecos_force eq ""){
       $gecos = "$vorname"." "."$nachname";
    } else {
       $gecos = $gecos_force;
    }

    if (not defined $type){
        $type="user";
    }

    if ($admin_class eq ${DevelConf::teacher}){
        # teachers
        $homedir = "${DevelConf::homedir_teacher}/$login";
        if (${Conf::teacher_samba_pw_must_change} eq "yes"){
            $sambapwdmustchange="0";
        } else {
            $sambapwdmustchange="2147483647";
        }
    } else {
        # students
        $homedir = "${DevelConf::homedir_pupil}/$admin_class/$login";
        if (${Conf::student_samba_pw_must_change} eq "yes"){
            $sambapwdmustchange="0";
        } else {
            $sambapwdmustchange="2147483647";
        }
    }

    if (defined $homedir_force){
        $homedir=$homedir_force;
    }

    my $description="";
    $description=$gecos;    
    my $cn="";
    $cn=$gecos;

    my $birthday_pg = &date_perl2pg($birthday_perl);

    # create crypt password for linux
    my $crypt_salt_format = '%s';
    my $salt = sprintf($crypt_salt_format,make_salt());
    my $linux_pass = "{CRYPT}" . crypt($pass,$salt);
    # create crypted passwords for samba
    my ($lmpassword,$ntpassword) = ntlmgen $pass;
    if($Conf::log_level>=3){
       print "Encrypted Password $pass : \n";
       print "   Samba NT: $ntpassword \n";
       print "   Samba LM: $lmpassword \n";
       print "   Linux   : $linux_pass \n";
    }

    my $dbh=&db_connect();
    my $uid_sys;
    my $uid_name_sys;

    # exists uid of user already? 
    ($uid_sys)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM userdata 
                                         WHERE uid='$login'");
    # exists uidnumber of user already?
    if (defined $id_force and $id_force ne "" and $id_force!=-1){ 
       ($uid_name_sys)= $dbh->selectrow_array( "SELECT uid 
                                  FROM userdata 
                                  WHERE uidnumber=$id_force");
    }

    if (not defined $uid_sys){
       $uid_sys="";
    }
    if (not defined $uid_name_sys){
       $uid_name_sys="";
    }

    # check if user exists
    if ($uid_sys ne ""){
        # uidnumber found
        my $uidnumber=$uid_sys;
        $uidnumber_auth=$uidnumber;
        print "user $login already exists in pg ($uidnumber)\n";
    } elsif ($uid_name_sys ne ""){
        # uid found
        my $uidname=$uid_name_sys;
        print "uidnumber $id_force exists already in pg ($uidname)\n";
        $uidnumber_auth=$id_force;
    } else {
    if ($DevelConf::testen==0) {

       $sql="SELECT manual_create_ldap_for_account('$login')";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       my $posix_account_id = $dbh->selectrow_array($sql);
       if($Conf::log_level>=3){
          print "   --> \$posix_account_id ist $posix_account_id \n\n";
       }

       #Freie UID holen
       my $uidnumber;
       my $stay_in_loop=1;
       my $name_of_uid;
       while($stay_in_loop==1) {
          $sql="select manual_get_next_free_uid()";
          if($Conf::log_level>=3){
             print "SQL: $sql\n";
          }
          $uidnumber = $dbh->selectrow_array($sql);

          # check in auth
          print "Checking uidnumber $uidnumber for existance: ";
          ($name_of_uid) = getpwuid($uidnumber);
          if (defined $name_of_uid){
              print "used by $name_of_uid\n";
              # stay in while loop
              $stay_in_loop=1;
          } else {
              $stay_in_loop=0;
              print "unused (using $uidnumber)\n";
          }
       }


       if (defined $id_force and $id_force ne "" and $id_force!=-1){
           # force the id if given as parameter
	   $uidnumber=$id_force;
       }

       $uidnumber_auth=$uidnumber;
       if($Conf::log_level>=3){
          print "   --> \$uidnumber ist $uidnumber \n\n";
       }


       if ($type eq "computer"){
           $gidnumber=515;
           $smb_homepath="";
           $smb_ldap_homepath="";
           $smb_homedrive="";
           $smb_acctflags="[WX]";
       } else {
          $smb_homepath="\\\\\\\\$servername\\\\$login";
          $smb_ldap_homepath="\\\\$servername\\$login";
          $smb_homedrive="H:";
          $smb_acctflags="[UX]";
          if ($type eq "examaccount"){
              # neue gruppe anlegen und gidnumber holen, falls erforderlich
              $gidnumber=&create_class_db_entry($admin_class,5);
	  } else {
              # neue gruppe anlegen und gidnumber holen, falls erforderlich
              $gidnumber=&create_class_db_entry($admin_class);
          }
       }

       # get_sid
       my $sid = &get_smb_sid();
       # smb user sid
       my $user_sid = &smb_user_sid($uidnumber,$sid);
       if($Conf::log_level>=3){
           print "USER-SID:        $user_sid\n";
       }
       # smb group sid
       my $group_sid = &smb_group_sid($gidnumber,$sid);
       if($Conf::log_level>=3){
           print "GROUP-SID:       $group_sid\n";
       }



       # User anlegen
       # 1. Tabelle posix_account
       # Pflichtfelder (laut Datenbank): id,uidnumber,uid,gidnumber,firstname
       $sql="INSERT INTO posix_account 
	  (id,uidnumber,uid,gidnumber,firstname,surname,
           homedirectory,gecos,loginshell,userpassword,description)
	  VALUES
	   ($posix_account_id,
            $uidnumber,
           '$login',
            $gidnumber,
           '$vorname',
           '$nachname',
           '$homedir',
           '$gecos',
           '$sh',
           '$linux_pass',
           '$description')";
        if($Conf::log_level>=3){
           print "SQL: $sql\n";
        }
        $dbh->do($sql);

       # 2. Tabelle samba_sam_account
       # Pflichtfelder (laut Datenbank): id
       $sql="INSERT INTO samba_sam_account
	 (id,sambasid,cn,sambalmpassword,sambantpassword,
          sambapwdlastset,sambalogontime,sambalogofftime,sambakickofftime,
          sambapwdcanchange,sambapwdmustchange,sambaacctflags,
          displayname,sambahomepath,sambahomedrive,sambalogonscript,
          sambaprofilepath,description,sambauserworkstations,
          sambaprimarygroupsid,sambadomainname,sambamungeddial,
          sambabadpasswordcount,sambabadpasswordtime,
          sambapasswordhistory,sambalogonhours)
	VALUES
	($posix_account_id,
         '$user_sid',
         '$cn',
         '$lmpassword',
         '$ntpassword',
         '$unix_epoc',
         '0',
         '2147483647',
         '2147483647',
         '0',
         '$sambapwdmustchange',
         '$smb_acctflags',
         '$gecos',
         '$smb_homepath',
         '$smb_homedrive',
         NULL,
         NULL,
         NULL,
         NULL,
         '$group_sid',
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
        )
	";
       if($Conf::log_level>=3){
          print "SQL: $sql\n";
       }
       $dbh->do($sql);

       # 3. Tabelle posix_account_details
       # Pflichtfelder (laut Datenbank); id

       $sql="INSERT INTO posix_account_details
	   ( id,schoolnumber,unid,adminclass,exitadminclass,subclass,
             creationdate,sophomorixstatus,quota,mailquota,firstpassword,
             birthname,title,gender,birthday,birthpostalcode,
             birthcity,denomination,class,classentry,schooltype,
             chiefinstructor,nationality,religionparticipation,
             ethicsparticipation,education,occupation,
             starttraining,endtraining)
	 VALUES
	  ($posix_account_id,
           1,
           '$unid',
           '$admin_class',
           '',
           '',
           '$pg_timestamp',
           '$sophomorix_status',
           '$quota',
           $mailquota,
           '$pass',
           '',
           '',
           '', 
           '$birthday_pg',
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           0,
           TRUE,
           FALSE,
           '',
           '',
           '19700101',
           '19700101')";
      if($Conf::log_level>=3){
         print "SQL: $sql\n";
      }
      $dbh->do($sql);
  } else {
      if($Conf::log_level>=3){
         print "Test:   Wrote entry into database\n";
      }
  }
  # create entry in auth system (no secondary groups)
  &auth_useradd($login,$uidnumber_auth,$gecos,$homedir,
                $admin_class,"",$sh,$type,$smb_ldap_homepath,
                $nachname)
  &db_disconnect($dbh);
  } # end 

}




=pod

=item I<set_sophomorix_passwd(login,string)>

Setzt das Passwort string in linux, samba, ...

=cut

sub set_sophomorix_passwd {
    my ($login,$pass) = @_;
    # create crypt password for liux
    my $crypt_salt_format = '%s';
    my $salt = sprintf($crypt_salt_format,make_salt());
    my $linux_pass = "{CRYPT}" . crypt($pass,$salt);
    # create crypted passwords for samba
    my ($lmpassword,$ntpassword) = ntlmgen $pass;
    my $dbh=&db_connect();
    my $sql="";
    $sql="SELECT id FROM userdata WHERE uid='$login'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($id)= $dbh->selectrow_array($sql);
    if (not defined $id){
       $id="";
       print "ERROR: User $login not found in database to set password!\n";
       $return=0;
    } else {

       if($Conf::log_level>=2){
          print "Setting password of user $login (Database ID: $id)...\n";
       }
       $sql="UPDATE posix_account SET userpassword='$linux_pass' 
            WHERE id = $id";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
       if ($DevelConf::testen==0) {
          $dbh->do($sql);
       } else {
          print "Test: setting password part 1\n";
       }
       # todo sambapwlastset  ????????? 
       $sql="UPDATE samba_sam_account 
              SET sambalmpassword='$lmpassword', sambantpassword='$ntpassword'
              WHERE id = $id";
       if($Conf::log_level>=3){
          print "SQL: $sql\n";
       }
       if ($DevelConf::testen==0) {
          $dbh->do($sql);
      } else {
          print "Test: setting password part 2\n";
      }
    }
    $dbh->disconnect();

    # set password in auth system
    &auth_passwd($login,$pass);
}





sub make_salt {
   my $length=32;
   $length = $_[0] if exists($_[0]);

   my @tab = ('.', '/', 0..9, 'A'..'Z', 'a'..'z');
   return join "",@tab[map {rand 64} (1..$length)];
}





# adds a class to the user database
sub create_class_db_entry {
    my $smallest_gidnumber=200;
    # standard: domain group
    my $samba_group_type="2";
    my $domain_group=1;
    my $local_group=0;
    my $displayname="";

    my ($class_to_add,$sub,
        $gid_force_number,$nt_groupname,$description) = @_;
    my ($class,$dept,$type,$mail,$quota,$mailquota) = ("","","","","",-1);
    if (not defined $sub){
        # standard: no subclass
	$sub=0;
        $type="adminclass";
    } elsif ($sub==0) {
        $type="adminclass";
    } elsif ($sub==2) {
        $type="project";
    } elsif ($sub==3) {
        $type="domaingroup";
        $domain_group=1;
        $local_group=0;
        $samba_group_type="2";
        $description="Domain Unix group";
    } elsif ($sub==4) {
        $type="teacher";
    } elsif ($sub==5) {
        $type="room";
    } elsif ($sub==6) {
        $type="localgroup";
        # change default
        $domain_group=0;
        $local_group=1;
        $samba_group_type="4";
        $description="Local Unix group";
    } else {
        $type="subclass";
    }
    if (not defined $gid_force_number){
        $gid_force_number=-1;
    }
    if (not defined $nt_groupname){
        #$nt_groupname="";
        $displayname=$class_to_add;
    } elsif ($nt_groupname eq ""){
        $displayname=$class_to_add;
    } else {
        $displayname=$nt_groupname;
    }
    if (not defined $description){
        $description="";
    }

    my %classes=();
    my $sql="";
    my $gidnumber;
    # SQL-Funktion aufrufen die Enträge in ldap_entries, ldap_entry_objclasses
    # und NextFreeUnixId macht und groups_id zurück gibt
    # der Username muss hier schon übergeben werden.
    my $dbh=&db_connect();
    my $gid_sys;
    my $gid_name_sys;

    # exists gid of class already? 
    ($gid_sys)= $dbh->selectrow_array( "SELECT gidnumber 
                                         FROM groups 
                                         WHERE gid='$class_to_add'" );
    # exists gidnumber of class already?
    if ($gid_force_number!=-1){ 
       ($gid_name_sys)= $dbh->selectrow_array( "SELECT gid 
                                  FROM groups 
                                  WHERE gidnumber = $gid_force_number");
    }
    if (not defined $gid_sys){
       # gid does not exist (has no gidnumber)
       $gid_sys="";
    }
    if (not defined $gid_name_sys){
       # gidnumber does not exist (has no gidnumber)
       $gid_name_sys="";
    }

    # check if group exists
    if ($gid_sys ne ""){
        # gidnumber found
        $gidnumber=$gid_sys;
        print "group $class_to_add exists already ($gidnumber)\n";
    } elsif ($gid_name_sys ne ""){
        # gid found
        $gidname=$gid_name_sys;
        print "gidnumber $gid_force_number exists already ($gidname)\n";
    } elsif ($gid_force_number<$smallest_gidnumber and $gid_force_number!=-1){
        # gidnumber to small
        print "gidnumber $gid_force_number is to small ",
              "(limit: $smallest_gidnumber)\n";
    } else {
        # begin adding group
        print "group does not exist -> adding $class_to_add\n";

        if ($gid_force_number!=-1){
	    $gidnumber=$gid_force_number;
            print "Forcing nonexisting $gidnumber as gidnumber\n";
        } else {
           my $name_of_gid;
           my $stay_in_loop=1;
           #Freie GID holen
           while($stay_in_loop==1) {
               $sql="select manual_get_next_free_gid()";
               if($Conf::log_level>=3){
                  print "\nSQL: $sql\n";
               }
               $gidnumber = $dbh->selectrow_array($sql);

               # check in auth
               print "Checking gidnumber $gidnumber for existance: ";
               ($name_of_gid) = getgrgid($gidnumber);
               if (defined $name_of_gid){
                   print "used by $name_of_gid\n";
                   # stay in while loop
                   $stay_in_loop=1;
               } else {
                   $stay_in_loop=0;
                   print "unused (using $gidnumber)\n";
               }
           }
        }

    # Gruppe anlegen, Funktion
    $sql="SELECT manual_create_ldap_for_group('$class_to_add')";
    if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
    }
    my $groups_id = $dbh->selectrow_array($sql);

    #Gruppe anlegen (2 Tabellen)
    #1. Tabelle groups
    #Pflichtfelder (laut Datenbank): alle

    $sql="INSERT INTO groups
         (id,gidnumber,gid)
	 VALUES
	 ($groups_id,$gidnumber,'$class_to_add')";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);

    # get_sid
    my $sid = &get_smb_sid();

    # smb group sid
    my $group_sid;

    if ($type eq "localgroup"){
         $group_sid = "S-1-5-32-".$gidnumber;
    } elsif ($gidnumber < 10000) {
        $group_sid="$sid"."-"."$gidnumber";
    } else {
         $group_sid = &smb_group_sid($gidnumber,$sid);
    }

    #2. Tabelle samba_group_mapping
    #Pflichtfelder (laut Datenbank) id
    # sambagrouptype (2=domaingroup(defaultgroup), 4=localgroup, 5=builtingroup)
    $sql="INSERT INTO samba_group_mapping
	 (id,gidnumber,sambasid,sambagrouptype,displayname,description,sambasidlist)
	 VALUES
	 ($groups_id,
          $gidnumber,
          '$group_sid',
          '$samba_group_type',
          '$displayname',
          '$description',
          NULL)";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);

    if ($sub==1){
        # adding a subclass
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,mailquota,schooltype,department,mailalias,maillist,type)
	    VALUES
  	    ($groups_id,
             NULL,
             NULL,
             '',
             '',
             FALSE,
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    } elsif ($sub==2){
        # adding a project
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,mailquota,schooltype,department,mailalias,maillist,type)
	    VALUES
  	    ($groups_id,
             NULL,
             NULL,
             '',
             '',
             FALSE,
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    } elsif ($sub==5){
        # adding a room
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,mailquota,schooltype,department,mailalias,maillist,type)
	    VALUES
  	    ($groups_id,
             NULL,
             NULL,
             '',
             '',
             FALSE,
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    } else {
        # adding a adminclass
        #3. Tabelle class_details
        $sql="INSERT INTO class_details
	    (id,quota,mailquota,schooltype,department,mailalias,maillist,type)
	    VALUES
  	    ($groups_id,
             'quota',
             -1,
             '',
             '',
             FALSE,
             FALSE,
             '$type')";	
        if($Conf::log_level>=3){
           print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
    }
    } # end adding group

    # create entry in auth system
    &auth_groupadd($class_to_add,$type,
                   $gidnumber,$displayname,
                   $domain_group,$local_group);
    return $gidnumber;
}




# updates a class in the user database
sub update_class_db_entry {
    my $class=shift;
    my $quota="";
    my $mailquota;
    my $mailalias;
    my $maillist;
    foreach my $param (@_){
       ($attr,$value) = split(/=/,$param);
       if($Conf::log_level>=2){
          printf "   %-18s : %-20s\n",$attr ,$value;
       }

       # quota
       if ($attr eq "Quota"){
	   $quota="$value";
           if ($quota eq ""){
             # accept empty quota
             print "   Quotastring is correct (empty). -> updating\n";
             push @class_details, "quota = ''";
           } else {
             # verify quota
             my $num=&Sophomorix::SophomorixBase::get_quota_fs_num();
             my @q_list = 
               &Sophomorix::SophomorixBase::check_quotastring($num,$quota);
             if ($q_list[0]!=-3){
                print "   Quotastring is correct. -> updating\n";
                push @class_details, "quota = '$quota'";
             } else {
                print "\nERROR ($q_list[0]): $quota is not correct",
                      " as quotastring.\n\n";
             }
	 }
       }

       # mailquota
       if    ($attr eq "MailQuota"){
	   $mailquota="$value";
           if ($mailquota eq "-1"){
             print "   MailQuota is correct (-1). -> updating\n";
	     push @class_details, "mailquota = $mailquota";
	   } else {
              # check if mailquota is positiv integer
              if ($mailquota=~/^[0-9]+$/){
                 print "   MailQuota is correct. -> updating\n";
	         push @class_details, "mailquota = $mailquota";
	      } else {
                 print "   MailQuota $mailquota not correct. -> must be integer\n";
              }
	   }
       }

       # mailalias
       if ($attr eq "Mailalias"){
	   $mailalias="$value";
	   push @class_details, "mailalias = $mailalias";
       }

       # mailing list
       if ($attr eq "Maillist"){
	   $maillist="$value";
	   push @class_details, "maillist = $maillist";
       }
    }

    # update
    my $dbh=&db_connect();
    my ($class_id)= $dbh->selectrow_array( "SELECT id 
                                         FROM groups 
                                         WHERE gid='$class'
                                        ");

    if (defined $class_id){
        my $class_options=join(", ",@class_details);

        $sql="UPDATE class_details SET $class_options
              WHERE id = $class_id";
        if($Conf::log_level>=3){
              print "\nSQL: $sql\n";
        }
        if ($class_options ne ""){
           $dbh->do($sql);
        }
        $dbh->disconnect();
    } else {
        print "\nERROR: Not updating $class (nonexisting)\n\n";
    }
}







# removes a class from the user database
sub remove_class_db_entry {
    my ($group) = @_;
    my $dbh=&db_connect();

    # Gruppe loeschen, Funktion
    my $sql="SELECT manual_delete_groups('$group')";
    if($Conf::log_level>=3){
        print "\nSQL: $sql\n";
    }
    #$dbh->do($sql);

    my $return = $dbh->selectrow_array($sql);
    if (defined $return){
        print "Group $return ($group) removed!\n";
    } else {
        print "\nERROR: Could not delete group $group \n\n";
    }
    &db_disconnect($dbh);

    # remove entry in auth system
    &auth_groupdel($group);
    return $return;
}


sub pg_adduser {
    # add a user to a secondary group
    # (removing a user is deleteuser_from_project)
    my ($user,$group) = @_;
    my $sql="";
    my $dbh=&db_connect();

    $sql="SELECT uidnumber FROM userdata WHERE uid='$user'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($uidnumber)= $dbh->selectrow_array($sql);

    $sql="SELECT gidnumber FROM classdata WHERE gid='$group'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($gidnumber)= $dbh->selectrow_array($sql);

    if (defined $uidnumber and defined $gidnumber){
        if($Conf::log_level>=2){
            print "   User $user has id  $uidnumber\n";
            print "   Group $group has id  $gidnumber\n";
            print "   Adding user $uidnumber to group $gidnumber\n";
        }
        $sql="SELECT memberuidnumber FROM groups_users 
                                  WHERE (gidnumber=$gidnumber
                                  AND memberuidnumber=$uidnumber)";
        if($Conf::log_level>=3){
            print "\nSQL: $sql\n";
        }
        my ($old_id)= $dbh->selectrow_array($sql);
        if (not defined $old_id){
            $sql="INSERT INTO groups_users 
                         VALUES ($gidnumber,$uidnumber);";
            if($Conf::log_level>=3){
                print "\nSQL: $sql\n";
            }
            print "   Adding user $user (${uidnumber}) to ",
                  "group $group ($gidnumber)\n";
            $dbh->do($sql);
        } else {
            print "   User $user(${uidnumber}) exists ",
                  "already in $group ($gidnumber)\n";
        }
    } else {
        if (not defined $uidnumber){
            print "   NOT adding user $user to group ",
                  "$group: user doesn't exist\n";
        } elsif (not defined $gidnumber){
            print "   NOT adding user $user to group ",
                  "$group: group doesn't exist\n";
        }
    }
}


sub pg_remove_all_secusers {
    # remove users from a group (only secondary memberships) 
    my ($group) = @_;
    my $sql="";
    my $dbh=&db_connect();

    $sql="SELECT gidnumber FROM classdata WHERE gid='$group'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($gidnumber)= $dbh->selectrow_array($sql);
    if($Conf::log_level>=2){
       print "   Removing $group with id  $gidnumber\n";
    }
    $sql="DELETE FROM groups_users WHERE gidnumber='$gidnumber'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
}



sub pg_get_group_list {
    # returns a list of membergroups of the user, 
    # first value in list is primary group
    my ($user) = @_;
    my $sql="";
    my @grp_list=();
    my $dbh=&db_connect();

    $sql="SELECT gid,uidnumber FROM userdata WHERE uid='$user'";
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    my ($gid,$uidnumber)= $dbh->selectrow_array($sql);

    push @grp_list, $gid;

    my $sth= $dbh->prepare( "SELECT userdata.uid,groups.gid 
                             FROM groups_users,userdata,groups 
                             WHERE groups_users.memberuidnumber=userdata.uidnumber 
                               AND groups_users.gidnumber=groups.gidnumber
                               AND userdata.uid='$user'
                             ORDER BY groups.gid" );
      $sth->execute();

    my $array_ref = $sth->fetchall_arrayref();

    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $sec_gid=${$array_ref}[$i][1];
        # add secondary group only when not eq to primary 
        if ($grp_list[0] ne $sec_gid){     
           push @grp_list, $sec_gid;
        }
        $i++;
    }   

    return @grp_list;
}


sub pg_get_group_type {
    my ($gid) = @_;
    my $dbh=&db_connect();
    # fetching project_id
    my ($id_sys,$gidnumber_sys)= $dbh->selectrow_array( "SELECT id,gidnumber 
                                         FROM groups 
                                         WHERE gid='$gid'");
    if (not defined $id_sys){
        # if not in pgldap
	return ("nonexisting",$gid,$gidnumber_sys);
    }    
    my ($type)= $dbh->selectrow_array( "SELECT type 
                                        FROM classdata 
                                        WHERE id='$id_sys'");

    if (not defined $type){
        # look at a users home
        my ($home)= $dbh->selectrow_array( "SELECT homedirectory 
                                            FROM userdata 
                                            WHERE gidnumber=$gidnumber_sys");
           if (not defined $home){
	       return ("nonexisting",$gid,$gidnumber_sys);
           } elsif ($home=~/^\/home\/workstations\//){
               # identify a workstation 
	       return ("room",$gid,$gidnumber_sys);
           } elsif ($home=~/^\/home\/administrators\//){
               # identify an administrator
               return ("administrator",$gid,$gidnumber_sys);
           } else {
               return ("unknown",$gid,$gidnumber_sys);
           }
    } elsif ($type eq "teacher"){
        # subclass
        return ("teacher",$gid,$gidnumber_sys);
    } elsif ($type eq "subclass"){
        # subclass
        return ("subclass",$gid,$gidnumber_sys);
    } elsif ($type eq "adminclass"){
        # adminclass
        return ("adminclass",$gid,$gidnumber_sys);
    } elsif ($type eq "room"){
        # adminclass
        return ("room",$gid,$gidnumber_sys);
    } elsif ($type eq "domaingroup"){
        # manually added group
        return ("domaingroup",$gid,$gidnumber_sys);
    } elsif ($type eq "localgroup"){
        # manually added group
        return ("localgroup",$gid,$gidnumber_sys);
    } elsif ($type eq "project"){
        my ($longname)= $dbh->selectrow_array( "SELECT longname
                                          FROM projectdata 
                                          WHERE id='$id_sys'");
        if (defined $longname){
            return ("project",$longname,$gidnumber_sys);
        } else {
            return ("project",$gid,$gidnumber_sys);
        }
    }
    &db_disconnect($dbh);
}


sub pg_get_group_members {
    # fetch all users from a group (pri or sec)
    my ($group) = @_; 
    my @members=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT DISTINCT uid
                             FROM memberdata 
                             WHERE gid='$group'
                                OR adminclass='$group'
                             ORDER BY uid");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $uid=${$array_ref}[$i][0];
        push @members, $uid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @members;
}



sub pg_get_adminclasses {
    # fetch all entries with type adminclasses
    my ($group) = @_;
    my %classes=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid from classdata WHERE type='adminclass'" );
      $sth->execute();

    my $array_ref = $sth->fetchall_arrayref();

    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        $classes{$gid}="";
        $i++;
    }   
    &db_disconnect($dbh);
    return %classes;
}

sub fetchadminclasses_from_school {
    # fetch all entries with type adminclasses
    my @admin_classes=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid from classdata 
                              WHERE type='adminclass'
                                AND NOT gid='${DevelConf::teacher}'
                              ORDER BY gid" );
      $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
#        if (not ($gid eq "speicher" or $gid eq "dachboden")){
        if (not ($gid eq "attic")){
            push @admin_classes, $gid;
        }
        $i++;
    }   
    &db_disconnect($dbh);
    return @admin_classes;
}


sub fetchsubclasses_from_school {
    # fetch all subclasses
    my @sub_classes=();
    my $dbh=&db_connect();

    my $sth= $dbh->prepare( "SELECT gid,COUNT(*) AS num
                             FROM userdata 
                             WHERE (subclass='A'
                                 OR subclass='B'
                                 OR subclass='C'
                                 OR subclass='D')
                                 GROUP BY gid" );
      $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        push @sub_classes, "$gid-A";
        push @sub_classes, "$gid-B";
        push @sub_classes, "$gid-C";
        push @sub_classes, "$gid-D";
        $i++;
    }   
    &db_disconnect($dbh);
    return @sub_classes;
}


sub fetchprojects_from_school {
    # fetch all projects
    my @projects=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid
                             FROM projectdata 
                             ORDER BY gid");

    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        push @projects, $gid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @projects;
}



sub fetchrooms_from_school {
    # fetch all rooms
    my @rooms=();
    my $dbh=&db_connect();
#    my $sth= $dbh->prepare( "SELECT DISTINCT gid
#                             FROM userdata 
#                             WHERE homedirectory LIKE '/home/workstations/%'
#                             ORDER BY gid");
#    $sth->execute();
#    my $array_ref = $sth->fetchall_arrayref();
#    my $i=0;
#    foreach ( @{ $array_ref } ) {
#        my $gid=${$array_ref}[$i][0];
#        push @rooms, $gid;
#        $i++;
#    }
    my $sth= $dbh->prepare( "SELECT gid
                             FROM classdata 
                             WHERE type='room'
                             ORDER BY gid");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        push @rooms, $gid;
        $i++;
    }

   
    &db_disconnect($dbh);
    return @rooms;
}


sub fetchclassrooms_from_school {
    # fetch all classrooms from /etc/linuxmuster/classrooms
    my @classrooms=();
    if (-e ${DevelConf::classroom_file}){
        open(CLASSROOMS, "${DevelConf::classroom_file}");
        while(<CLASSROOMS>) {
            chomp(); # Returnzeichen abschneiden
            s/\s//g; # Spezialzeichen raus
            if ($_ eq ""){next;} # Wenn Zeile Leer, dann weiter
            push @classrooms, $_;
        }
     close(CLASSROOMS);
     }
     return @classrooms;
}


sub fetchworkstations_from_school {
    # fetch all subclasses
    my @rooms=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT uid
                             FROM userdata 
                             WHERE homedirectory LIKE '/home/workstations/%'
                             ORDER BY uid");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        push @rooms, $gid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @rooms;
}



sub fetchworkstations_from_room {
    # fetch all subclasses
    my ($gid) = @_;
    my @ws=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT uid
                             FROM userdata 
                             WHERE homedirectory LIKE '/home/workstations/%'
                             AND gid='$gid'
                             ORDER BY uid");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $uid=${$array_ref}[$i][0];
        push @ws, $uid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @ws;
}



sub fetchadministrators_from_school {
    # fetch administrators with /home/administrators
    my @admins = ();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "
                   SELECT uid
                   FROM userdata 
                   WHERE homedirectory LIKE '${DevelConf::homedir_all_admins}/%'
                   ORDER BY uid");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        push @admins, $gid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @admins;
}



sub fetchusers_sophomorix {
    # fetch students,teachers and workstation users in a hash
    my @ws = &fetchworkstations_from_school();
    my @teachers=&fetchstudents_from_adminclass(${DevelConf::teacher});
    my @students=&Sophomorix::SophomorixAPI::fetchstudents_from_school();
    my @administrators=&fetchadministrators_from_school();
    my @users=(@teachers,@students,@ws,@administrators);

    foreach my $user (@users){
        $users{$user}="user";
    }
    return %users;
}





###########################################################################
# CHECKED, NEW
###########################################################################



# convert dates from 1988-12-01 to 01.12.1988
sub date_pg2perl {
    my ($string) = @_;
    if (not defined $string){
	$string="";
    }
    my $perl="";
    if ($string ne ""){
       my ($year,$month,$day)=split(/-/,$string);
       $perl="$day"."."."$month"."."."$year";
   }
    return $perl;
}



# convert dates from 01.12.1988 to 1988-12-01
sub date_perl2pg {
    my ($string) = @_;
    my $pg="";
    if ($string ne ""){
       my ($day,$month,$year)=split(/\./,$string);
       $pg="$year"."-"."$month"."-"."$day";
    } else {
        # what should be saved, when nothing should be saved
#	$pg="3333-03-03";
	$pg="NULL";
    }
    return $pg;
}


# reads the user database into perl hashes.
# the scripts all work with the perl hashes (instead of the database itself)
sub get_sys_users {
   my $number=1;

   # Result-hashes
   my %identifier_adminclass=();
   my %identifier_login=();  
   my %identifier_subclass=();
   my %identifier_status=();
   my %identifier_toleration_date=();
   my %identifier_deactivation_date=();
   my %unid_identifier=();
   my %identifier_exit_adminclass=();
   my %identifier_account_type=();
   my %identifier_usertoken=();
   my %identifier_sc_tol=();

   my $dbh=&db_connect();

# select the columns that i need
my $sth= $dbh->prepare( "SELECT uid, firstname, surname, birthday, adminclass, exitadminclass, unid, subclass, tolerationdate, deactivationdate, sophomorixstatus, usertoken, scheduled_toleration FROM userdata" );
$sth->execute();

my $array_ref = $sth->fetchall_arrayref();

foreach my $row (@$array_ref){
    # split the array, to give better names
    # or use numbers and look in the SELECT statement
    my $account_type="",

    my ($login,
        $firstname,
        $surname,
        $birthday_pg,
        $admin_class,
        $exit_admin_class,
        $unid,
        $subclass,
        $toleration_date_pg,
        $deactivation_date_pg,
        $status,
        $usertoken,
        $scheduled_toleration,
        ) = @$row;


   # date strings must be defined
   if (not defined $toleration_date_pg){
       $toleration_date_pg="";
   }
   if (not defined $deactivation_date_pg){
       $deactivation_date_pg="";
   }

   # status have only sophomorix users, 
   # others (smbldap-useadd, ...) are considered permanent
   if (not defined $status){$status="P"}
   if (not defined $admin_class){$admin_class=""}
   if (not defined $birthday_pg){$birthday_pg="1970-01-01"}
   if (not defined $unid){$unid=""}
   if (not defined $subclass){$subclass=""}
   if (not defined $exit_admin_class){$exit_admin_class=""}
   if (not defined $usertoken){$usertoken=""}
   if (not defined $scheduled_toleration){$scheduled_toleration=""}

   # exclude one user ????????ß
   if ($login eq "NextFreeUnixId"){
       next;
   }       

#    print "\nEntry:   @{ $row }\n";   # todo


    my $birthday = &date_pg2perl($birthday_pg);
    my $toleration_date = &date_pg2perl($toleration_date_pg);
    my $deactivation_date = &date_pg2perl($deactivation_date_pg);

    my $identifier=join("",
         ($surname,";",
          $firstname,";",
          $birthday));

   # print what was selected
   if($Conf::log_level>=3){
      print "\n";
      print "User $number  Attributes (MUST): \n";
      print "  Login        :   $login \n"; 
      print "  AdminClass   :   $admin_class \n";
      print "  Birthday(pg) :   $birthday_pg \n";
      print "  Birthday(pl) :   $birthday \n";
      print "  Identifier   :   $identifier \n";

      print "User Attributes (MAY): \n";

      # unid is optional
      if ($unid ne "") {
         print "  Unid                 :   $unid \n" ;
      } else {
         print "  Unid                 :   --- \n" ;
      }

      # usertoken is optional
      if ($usertoken ne "") {
         print "  Usertoken            :   $usertoken \n" ;
      } else {
         print "  Usertoken            :   --- \n" ;
      }

      # subclass is optional
      if ($subclass ne "") {
         print "  SubClass             :   $subclass \n" ;
      } else {
         print "  SubClass             :   --- \n" ;
      }

      # Status
      if ($status ne "") {
         print "  Status               :   $status \n" ;
      } else {
         print "  Status               :   --- \n" ;
      }

      # TolerationDate is optional
      if ($toleration_date ne "") {
         print "  TolerationDate       :   $toleration_date \n" ;
      } else {
         print "  TolerationDate       :   --- \n" ;
      }

      # ScheduledToleration is optional
      if ($scheduled_toleration ne "") {
         print "  ScheduledToleration  :   $scheduled_toleration \n" ;
      } else {
         print "  ScheduledToleration  :   --- \n" ;
      }

      # DeactivationDate is optional
      if ($deactivation_date ne "") {
         print "  DeactivationDate     :   $deactivation_date \n" ;
      } else {
         print "  DeactivationDate     :   --- \n" ;
      }

      # ExitAdminClass is optional
      if ($exit_admin_class ne "") {
         print "  ExitAdminClass       :   $exit_admin_class \n" ;
      } else {
         print "  ExitAdminClass       :   --- \n" ;
      }

      # AccountType is optional
      if ($account_type ne "") {
         print "  AccountType          :   $account_type \n" ;
      } else {
         print "  AccountType          :   --- \n" ;
      }

          print "\n";
   }# end loglevel

   if (not defined $toleration_date){$toleration_date=""}
   if (not defined $deactivation_date){$deactivation_date=""}
   if (not defined $account_type){$account_type=""}

   # add the user to the hashes
   $identifier_adminclass{$identifier} = "$admin_class";
   $identifier_login{$identifier} = "$login";


   # unid is optional
   if ($unid ne "") {        
      $unid_identifier{$unid} = "$identifier";
   }

   # subclass is optional
   if ($subclass ne "") {        
      $identifier_subclass{$identifier} = "$subclass";
   }

   if ($status ne ""){
      $identifier_status{$identifier} = "$status";
   }

   # TolerationDate is optional
   if ($toleration_date ne "") {        
      $identifier_toleration_date{$identifier} = "$toleration_date";
   }

   # DeactivationDate is optional
   if ($deactivation_date ne "") {        
      $identifier_deactivation_date{$identifier} = "$deactivation_date";
   }

   # ScheduledToleration is optional
   if ($scheduled_toleration ne "") {        
      $identifier_sc_tol{$identifier} = "$scheduled_toleration";
   }

   # ExitAdminClass is must
   #if ($exit_admin_class ne "") {        
      $identifier_exit_adminclass{$identifier} = "$exit_admin_class";
   #}

   # AccountType is optional
   if ($account_type ne "") {        
      $identifier_account_type{$identifier} = "$account_type";
   }

   # usertoken is optional
   if ($usertoken ne "") {        
      $identifier_usertoken{$identifier} = "$usertoken";
   }

   # increase counter for users
   $number++;

}
   &db_disconnect($dbh);
   # returns some Hashes, as a list
   # 1:  identifier - login
   # 2:  identifier - sophomorixAdminClass
   # 3:  identifier - sophomorixStatus
   # 4:  identifier - sophomorixSubClass
   # 5:  identifier - sophomorixTolerationDate
   # 6:  identifier - sophomorixDeaktivationDate
   # 7:  unid - sophomorixIdentifier
   return(\%identifier_login, 
          \%identifier_adminclass, 
          \%identifier_status,
          \%identifier_subclass,
          \%identifier_toleration_date,
          \%identifier_deactivation_date,
          \%unid_identifier,
          \%identifier_exit_adminclass,
          \%identifier_account_type,
          \%identifier_usertoken,
          \%identifier_sc_tol,
         );
}





# ===========================================================================
# Hash with all forbidden loginnames
# ===========================================================================
sub  forbidden_login_hash{
   my %forbidden_login_hash = %DevelConf::forbidden_logins;
   my $dbh=&db_connect();

   # users in db
   my $sth= $dbh->prepare( "SELECT uid FROM userdata" );
   $sth->execute();
   my $array_ref = $sth->fetchall_arrayref();
   foreach my $row (@$array_ref){
      my ($login) = @$row;
      $forbidden_login_hash{$login}="login in db";

   }

   # users in /etc/passwd
   if (-e "/etc/passwd"){
        open(PASS, "/etc/passwd");
        while(<PASS>) {
            my ($login)=split(/:/);
            $forbidden_login_hash{$login}="login in /etc/passwd";
        }
        close(PASS);
   }

   # future groups in schueler.txt
   if (-e "$DevelConf::users_pfad/schueler.txt"){
        open(STUDENTS, "$DevelConf::users_pfad/schueler.txt");
        while(<STUDENTS>) {
            my ($group)=split(/;/);
            $forbidden_login_hash{$group}="future group in schueler.txt";
         }
     close(STUDENTS);

   }

   # groups in db
   my $sth2= $dbh->prepare( "SELECT gid FROM classdata" );
   $sth2->execute();
   my $array_ref_2 = $sth2->fetchall_arrayref();

   foreach my $row (@$array_ref_2){
      my ($group) = @$row;
      $forbidden_login_hash{$group}="unix group in db";

   }

   # project longnames in db
   my $sth3= $dbh->prepare( "SELECT longname FROM projectdata" );
   $sth3->execute();
   my $array_ref_3 = $sth3->fetchall_arrayref();

   foreach my $row (@$array_ref_3){
      my ($longname) = @$row;
      $forbidden_login_hash{$longname}="project longname in db";

   }

   # groups in /etc/group
   if (-e "/etc/group"){
        open(GROUP, "/etc/group");
        while(<GROUP>) {
            my ($group)=split(/:/);
            $forbidden_login_hash{$group}="group in /etc/group";
         }
     close(GROUP);

   }

   &db_disconnect($dbh);
   # Ausgabe aller Loginnamen, die schon vorhanden sind
   if($Conf::log_level>=3){
       #&titel("Vorhandene Login-Namen");
       print("Login-Name:                    ",
             "                                   Status:\n");
       print("================================",
             "===========================================\n");
       while (($k,$v) = each %forbidden_login_hash){
           printf "%-60s %3s\n","$k","$v";
       }
   }

   return %forbidden_login_hash;
}




# ===========================================================================
# Hash with all forbidden project names beginning with p_
# ===========================================================================
sub  forbidden_project_hash{
   my %forbidden_project_hash=();
   my $dbh=&db_connect();
   # users in db
   my $sth= $dbh->prepare( "SELECT gid FROM projectdata" );
   $sth->execute();
   my $array_ref = $sth->fetchall_arrayref();
   foreach my $row (@$array_ref){
      my ($project) = @$row;
      $forbidden_project_hash{$project}="project in db";
   }
   &db_disconnect($dbh);
   # Ausgabe aller Loginnamen, die schon vorhanden sind
   if($Conf::log_level>=3){
       print("Project-Name(unix group name):                    ",
             "                                   Status:\n");
       print("================================",
             "===========================================\n");
       while (($k,$v) = each %forbidden_project_hash){
           printf "%-60s %3s\n","$k","$v";
       }
   }
   return %forbidden_project_hash;
}



# returns a list of users with status D,T,S,A
# i.e. the users for  teach-in
sub get_teach_in_sys_users {
   my @toleration=();
   my $dbh=&db_connect();

   # select the columns that i need
   my $sth= $dbh->prepare( "SELECT uid, firstname, surname, 
                                   birthday, sophomorixstatus 
                            FROM userdata 
                            WHERE sophomorixstatus='T' 
                               OR sophomorixstatus='S' 
                               OR sophomorixstatus='D' 
                               OR sophomorixstatus='A'" );
   $sth->execute();

   my $array_ref = $sth->fetchall_arrayref();

   foreach my $row (@$array_ref){
       # split the array, to give better names
       my $identifier="";
       my ($login,
           $first,
           $last,
           $birth,
           $status)=@$row;

       my $birthday_perl = &date_pg2perl($birth);

       $identifier=$last.";".$first.";".$birthday_perl;
       push @toleration, $identifier;

   }
   return @toleration;
}




# returns a list of the following lines from all users:
# Syntax:
#   class;firstname lastname;loginname;FirstPassword;birthday;  

sub get_print_data {
    my @lines=();
    my $dbh=&db_connect();
    # select for students and teachers 
    # the columns that i need
    my $sth= $dbh->prepare( "SELECT uid, firstname, 
                                    surname, birthday, 
                                    adminclass, firstpassword,
                                    sophomorixstatus
                             FROM userdata
                             WHERE (homedirectory LIKE '/home/students%'
                                OR gid='$DevelConf::teacher') 
                            " );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();

    foreach my $row (@$array_ref){
        # split the array, to give better names
        my ($login,
            $firstname,
            $surname,
            $birthday_pg,
            $admin_class,
            $firstpass,
            $sophomorixstatus
           ) = @$row;
        if (not defined $sophomorixstatus){
            next;
        }
        my $birthday = &date_pg2perl($birthday_pg);
        # assemble string
        my $string="$admin_class".";".
                   "$firstname $surname".";".
                   "$login".";".
                   "$firstpass".";".
                   "$birthday".";"."\n";    
        push @lines, $string;
    }
    return @lines;
}


=head1 update_user_db_entry

Parameter 1: Loginname of user to be updated

Parameter 2: List with Attribute=Value

=cut

# this function changes the fields of the user login

sub update_user_db_entry {
    my $login=shift;
    my $admin_class="";
    my $gid_name="";
    my $gid_number;
    my $home_dir="";
    my $lastname="";
    my $firstname="";
    my $gecos="";
    my $first_pass="";
    my $birthday="";
    my $unid="";
    my $exitunid="";
    my $subclass="";
    my $status="";
    my $toleration_date="",
    my $deactivation_date="";
    my $sc_toleration_date="",
    my $exit_admin_class="";
    my $usertoken="";
    my $account_type="";
    my $quota="";
    my $mailquota=-1;
    my $new_login="";

    # decide if auth_usermove must be called (1) or not
    my $usermove=0;
    my $firstnameupdate=0;
    my $lastnameupdate=0;
    my $gecosupdate=0;

    my @posix=();
    my @posix_details=();
    my @samba=();
  
    my $dbh=&db_connect();
    my $sql="";

    # fetch old data
    my ($old_home,$old_type,$old_gecos,$old_group,$old_uidnumber,
        $old_sambahomepath) = &fetchdata_from_account($login);

    
    # Check of Parameters
    foreach my $param (@_){
       ($attr,$value) = split(/=/,$param);
       if($Conf::log_level>=2){
          printf "   %-18s : %-20s\n",$attr ,$value;
       }
       if    ($attr eq "AdminClass"){
	   $admin_class="$value";
	   push @posix_details, "adminclass = '$admin_class'";
       }
       elsif ($attr eq "Name"){
           $firstnameupdate=1;
           $firstname="$value";
	   push @posix, "firstname = '$firstname'";
       }
       elsif ($attr eq "LastName"){
           $lastnameupdate=1;
           $lastname="$value";
	   push @posix, "surname = '$lastname'";
       }
       elsif ($attr eq "Gecos"){
           $gecosupdate=1;
           $gecos="$value";
	   push @posix, "gecos = '$gecos'";
	   push @samba, "displayname = '$gecos'";
	   push @samba, "cn = '$gecos'";
	   push @posix, "description = '$gecos'";
	   push @samba, "description = '$gecos'";
       }
       elsif ($attr eq "Uid"){
           $new_login="$value";
	   push @posix, "uid = '$new_login'";
           # homedirectory
	   my $new_home=$old_home;
           $new_home=~s/\/${login}$/\/${new_login}/;
           push @posix, "homedirectory = '$new_home'";
           # sambahomepath
           my $new_sambahomepath=$old_sambahomepath;
           $new_sambahomepath=~s/\\${login}$/\\\\${new_login}/;
           $new_sambahomepath=~s/^\\\\/\\\\\\\\/;
           # smabahomepath = '\\\\server\\user'  is required
	   push @samba, "sambahomepath = '$new_sambahomepath'";
       }
       elsif ($attr eq "FirstPass"){
           $first_pass="$value";
	   push @posix_details, "firstpassword = '$first_pass'";
       }
       elsif ($attr eq "Birthday"){
           $birthday = &date_perl2pg($value);
	   push @posix_details, "birthday = '$birthday'";
       }
       elsif ($attr eq "Unid"){
           $unid="$value";
	   push @posix_details, "unid = '$unid'";
       }
       elsif ($attr eq "ExitUnid"){
           $exit_unid="$value";
	   push @posix_details, "exitunid = '$exit_unid'";
       }
       elsif ($attr eq "SubClass" or $attr eq "Subclass"){
           $subclass="$value";
	   push @posix_details, "subclass = '$subclass'";
       }
       elsif ($attr eq "Status"){
           $status="$value";
	   push @posix_details, "sophomorixstatus = '$status'";
       }
       elsif ($attr eq "TolerationDate"){
           $toleration_date=&date_perl2pg($value);
           if ($toleration_date ne "NULL"){
	       $toleration_date="'".$toleration_date."'";
           }
	   push @posix_details, "tolerationdate = $toleration_date";
       }
       elsif ($attr eq "DeactivationDate"){
           $deactivation_date=&date_perl2pg($value);
           if ($deactivation_date ne "NULL"){
	       $deactivation_date="'".$deactivation_date."'";
           }
	   push @posix_details, "deactivationdate = $deactivation_date";
       }
       elsif ($attr eq "ScheduledToleration"){
           $sc_toleration_date=&date_perl2pg($value);
           if ($sc_toleration_date ne "NULL"){
	       $sc_toleration_date="'".$sc_toleration_date."'";
           }
	   push @posix_details, "scheduled_toleration = $sc_toleration_date";
       }
       elsif ($attr eq "ExitAdminClass"){
           $exit_admin_class="$value";
           push @posix_details, "exitadminclass = '$exit_admin_class'";
       }
       elsif ($attr eq "Usertoken"){
           $usertoken="$value";
           push @posix_details, "usertoken = '$usertoken'";
       }
       elsif ($attr eq "Gid"){
           $gid_name="$value";
           # call auth_usermove later
           $usermove=1;
           print " ****adding $gid_name\n";
           # neue gruppe anlegen und gidnumber holen, falls erforderlich
           $gid_number=&create_class_db_entry($gid_name);
           # homedirectory
           if ($gid_name eq ${DevelConf::teacher}) {
              # in klasse lehrer versetzten
              $home_dir="${DevelConf::homedir_teacher}/${login}";
           } elsif ($gid_name eq "attic") {
              # move to attic
              $home_dir="${DevelConf::attic}/${login}";
           } else {
              # in andere Klasse versetzten (auch attic)
              $home_dir="${DevelConf::homedir_pupil}/${gid_name}/${login}";
           } 
           # groupsid
           my $sid = &get_smb_sid();
           my $group_sid = &smb_group_sid($gid_number,$sid);
           # add to SQL
           push @posix, "gidnumber = '$gid_number'";
           push @posix, "homedirectory = '$home_dir'";
           push @samba, "sambaprimarygroupsid = '$group_sid'";
       }
       elsif ($attr eq "AccountType"){
           $account_type="$value";
           # todo
       }
       elsif ($attr eq "Quota"){
           $quota="$value";
           push @posix_details, "quota = '$quota'";
       }
       elsif ($attr eq "MailQuota"){
           $mailquota="$value";
           if (not defined $mailquota or $mailquota eq ""){
               push @posix_details, "mailquota = -1";
           } else {
               push @posix_details, "mailquota = '$mailquota'";
           }
       }
       else {print "Attribute $attr unknown\n"}
    }

    $sql="SELECT id FROM userdata 
          WHERE uid='$login'";
    if($Conf::log_level>=3){
        print "\nSQL: $sql\n";
    }
    my ($id)=$dbh->selectrow_array($sql);

    if (defined $id){
       # if user found in database
       if($Conf::log_level>=3){
           print "Retrieved Id of $login: $id \n";
       }
       # updating posix_account
       my $posix=join(", ",@posix);
       if ($posix ne ""){
          $sql="UPDATE posix_account
                SET 
                $posix
                WHERE id = $id
               ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
          $dbh->do($sql);
       }

       # updating posix_account_details
       my $posix_details=join(", ",@posix_details);
       if ($posix_details ne ""){
          $sql="UPDATE posix_account_details
                SET 
                $posix_details
                WHERE id = $id
               ";
          if($Conf::log_level>=3){
             print "\nSQL: $sql\n";
          }
          $dbh->do($sql);
       }
       # updating samba_sam_account
       my $samba=join(", ",@samba);
       if ($samba ne ""){
          $sql="UPDATE samba_sam_account
                SET 
                 $samba
                WHERE id = $id
               ";
          if($Conf::log_level>=3){
             print "\nSQL: $sql\n";
          }
          $dbh->do($sql);
       }
    } else {
        print "Could not retrieve id of $login \n";
        print "I cannot update the entry of $login \n";
    }

    $dbh->disconnect();

    # update authentication system
    if ($usermove==1){
       &auth_usermove($login,$gid_name,$home_dir,$old_group);
    }
    if ($firstnameupdate==1){
       &auth_firstnameupdate($login,$firstname);
    }
    if ($lastnameupdate==1){
       &auth_lastnameupdate($login,$lastname);
    }
    if ($gecosupdate==1){
       &auth_gecosupdate($login,$gecos);
    }
    # ??? besser was sinnvolles
    return 1;
}



# this function removes a user entry in the database 
sub remove_user_db_entry {
    my ($login) = @_;
    my $dbh=&db_connect();
    my $sql="";

    # what to do
    $sql="SELECT manual_delete_account('$login')";
    if($Conf::log_level>=3){
       print "SQL: $sql\n";
    }
    my $uidnumber = $dbh->selectrow_array($sql);
    if (not defined $uidnumber){
        print "Cold not delete nonexisting user $login\n";
    } else {
        print "Deleted User $login ($uidnumber)\n";
    }
    &db_disconnect($dbh);

    # delete entry in auth system
    &auth_userkill($login);
}


# ===========================================================================
# User DE-aktivieren
# ===========================================================================

# deactivate a users login, ...

sub user_deaktivieren {
   my ($login) = @_;
   if($Conf::log_level>=2){
      print "Deactivating $login ...\n";
   }

   # disabling samba login in auth system
   &auth_disable($login);

   # disabling posix login in auth system
   my $ldap=&auth_connect();
   print "   * ldap: Disabling posix account of $login:\n";
   my ($ldappw,$ldap_rootdn,$dbpw,$suffix)=&fetch_ldap_pg_passwords();
   my $msg = $ldap->search(
          base => "ou=accounts,$suffix",
          scope => "sub",
          filter => ("uid=$login")
      );

   my $entry = $msg->entry(0);
   my $oldpass;

   $oldpass=$entry->get_value('userPassword');
   print "       Unix password: $oldpass\n";

   if (not defined $oldpass){
       print "   User $login not found in ldap to disable posix-account!\n";
   } elsif ($oldpass=~m/!$/) {
       print "       Posix account of $login is already disabled in ldap!\n";
   } else {
       # append ! to pasword
       $oldpass="$oldpass"."!";
       # replace password
       print "       Replacing password with ${oldpass}\n";
       my $result = $ldap->modify( $entry->dn(),
                    'replace' => { 'userPassword' => $oldpass }); 
   }
   &auth_disconnect($ldap);

   # disable in pg
   my $dbh=&db_connect();
   my $sql="";

   # samba
   print "   * pg: Disabling samba account\n";
   $sql="UPDATE samba_sam_account
         SET 
         sambaacctflags = '[DUX]'
         WHERE id = (SELECT id from userdata WHERE uid='$login')
        ";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   $dbh->do($sql);

   # linux
   print "   * pg: Disabling posix account\n";
   # fetch the old crypted password
   $sql="SELECT userpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($crypt_pass)= $dbh->selectrow_array($sql);
   print "       Unix password: $crypt_pass\n";

   if (not defined $crypt_pass){
       print "       User $login not found in pg to disable posix-account!\n";
   } elsif ($crypt_pass=~m/!$/) {
       print "       Unix account of $login is already disabled in pg!\n";
   } else {
       # append ! to pasword
       $crypt_pass="$crypt_pass"."!";
       # replace password
       print "       Replacing password with $crypt_pass in pg\n";
       $sql="UPDATE posix_account
             SET 
             userpassword = '$crypt_pass'
             WHERE uid = '$login'
            ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
          $dbh->do($sql);
 
   }
   &db_disconnect($dbh);


   # ToDo
   # mailabruf
   # ToDo
   # public:html : sperren
#   system  "chmod 0001 $www_home";  # gesperrt
   # Ende des Eintrags
   if($Conf::log_level>=2){
      print "\n";
    }
}





# ===========================================================================
# User RE-aktivieren
# ===========================================================================

# enables a users login, ...

sub user_reaktivieren {
   my ($login) = @_;
   if($Conf::log_level>=2){
      print "Reactivating $login ...\n";
   }

   # enabling samba login in auth system
   &auth_enable($login);

   # enabling posix login in auth system
   my $ldap=&auth_connect();
   print "   * ldap: Enabling posix account of $login:\n";
   my ($ldappw,$ldap_rootdn,$dbpw,$suffix)=&fetch_ldap_pg_passwords();
   my $msg = $ldap->search(
          base => "ou=accounts,$suffix",
          scope => "sub",
          filter => ("uid=$login")
      );

   my $entry = $msg->entry(0);
   my $oldpass;

   $oldpass=$entry->get_value('userPassword');
   print "       Unix password: $oldpass\n";

   if (not defined $oldpass){
       print "   User $login not found in ldap to enable posix-account!\n";
   } elsif (not $oldpass=~m/!/) {
       print "       Posix account of $login is already enabled in ldap!\n";
   } else {
       # remove ! from pasword
       $oldpass=~s/!$//g;
       # replace password
       print "       Replacing password with ${oldpass}\n";
       my $result = $ldap->modify( $entry->dn(),
                    'replace' => { 'userPassword' => $oldpass }); 
   }
   &auth_disconnect($ldap);

   # enable in pg
   my $dbh=&db_connect();
   my $sql="";

   # samba
   print "   * pg: Enabling samba account\n";
   $sql="UPDATE samba_sam_account
         SET 
         sambaacctflags = '[UX]'
         WHERE id = (SELECT id from userdata WHERE uid='$login')
        ";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   $dbh->do($sql);

   # linux
   print "   * pg: Enabling posix account\n";
   # fetch the old crypted password
   $sql="SELECT userpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($crypt_pass)= $dbh->selectrow_array($sql);
   print "       Unix password: $crypt_pass\n";

   if (not defined $crypt_pass){
       print "       User $login not found in pg to enable posix-account!\n";
   } elsif (not $crypt_pass=~m/!/) {
       print "       Unix account of $login is already enabled in pg!\n";
   } else {
       # remove ! from pasword
       $crypt_pass=~s/!$//g;
       # replace password
       print "       Replacing password with $crypt_pass \n";
       $sql="UPDATE posix_account
             SET 
             userpassword = '$crypt_pass'
             WHERE uid = '$login'
            ";
       if($Conf::log_level>=3){
          print "\nSQL: $sql\n";
       }
          $dbh->do($sql);
 
   }
   &db_disconnect($dbh);

   # ToDo
   # mailabruf
   # ToDo
   # public:html:
      # NICHT entsperren
}




sub create_project {
    # reads from projects_db and creates the project in the system
    my ($project,$create,$p_long_name,
        $p_add_quota,$p_add_mail_quota,
        $p_status,$p_join,$pg_timestamp,
        $p_max_members,$p_members,$p_admins,
        $p_groups,$p_projects,
        $p_mailalias,$p_maillist,$ref_repair) = @_;
    # switch if longname has changed
    my $longname_changed=0;

    # check if unix group exists and if its a project
    my $dbh=&db_connect();
    # fetch old data
    my ($old_id,$old_name,$old_long_name,$old_add_quota,$old_add_mail_quota,
        $old_max_members,$old_status,$old_join,
        $old_mailalias,$old_maillist)= $dbh->selectrow_array( 
                         "SELECT id,gid,longname,addquota,
                                 addmailquota,maxmembers,sophomorixstatus,
                                 joinable,mailalias,maillist 
                          FROM projectdata 
                          WHERE gid='$project'
                         ");
    # Merging information:
    # LongName
    if (not defined $p_long_name){
	if (defined $old_long_name){
           $p_long_name=$old_long_name;          
        } else {
	    $p_long_name=$project; # use short name
        }
    } else {
	$longname_changed=1;
    }

    # AddQuota
    if (not defined $p_add_quota){
	if (defined $old_add_quota){
           $p_add_quota=$old_add_quota;          
        } else {
	    $p_add_quota="quota";
        }
    }

    # AddMailQuota
    if (not defined $p_add_mail_quota){
	if (defined $old_add_mail_quota){
           $p_add_mail_quota=$old_add_mail_quota;          
        } else {
	    $p_add_mail_quota=0;
        }
    }

    # MaxMembers
    if (not defined $p_max_members){
	if (defined $old_max_members){
           $p_max_members=$old_max_members;          
        } else {
	    $p_max_members=0;
        }
    }

    # SophomorixStatus
    if (not defined $p_status){
	if (defined $old_status){
           $p_status=$old_status;          
        } else {
	    $p_status="P";
        }
    }

    # Joinable
    if (not defined $p_join or $p_join eq ""){
	if (defined $old_join){
	    if ($old_join==0){
               $p_join="FALSE";   
	    } elsif ($old_join==1){
               $p_join="TRUE";   
	    }
        } else {
	    $p_join="TRUE";
        }
    }

    # mailalias
    if ($p_mailalias eq ""){
	if (defined $old_mailalias){
	    if ($old_mailalias==0){
               $p_mailalias="FALSE";   
	    } else{
               $p_mailalias="TRUE";   
	    }
        } else {
	    $p_mailalias="FALSE";
        }
    }

    # maillist
    if ($p_maillist eq ""){
	if (defined $old_maillist){
	    if ($old_maillist==0){
               $p_maillist="FALSE";   
	    } else{
               $p_maillist="TRUE";   
	    }
        } else {
	    $p_maillist="FALSE";
        }
    }

    print "1) Data for the Project:\n";
    print "   LongName:         $p_long_name\n";
    print "   AddQuota:         $p_add_quota MB\n";
    print "   AddMailQuota:     $p_add_mail_quota MB\n";
    print "   MaxMembers:       $p_max_members\n";
    print "   SophomorixStatus: $p_status\n";
    print "   Join:             $p_join\n";
    print "   Mailalias:        $p_mailalias\n";
    print "   Maillist:         $p_maillist\n";
    print "   PG Timestamp:     $pg_timestamp\n";

    # what to do if group doesnt exist
    if (not defined $old_id){
        if ($create==1){
           # create the group
           my $gidnumber=&create_class_db_entry($project,2);
           # fetching the table id
           my ($id)= $dbh->selectrow_array( "SELECT id 
                                             FROM groups 
                                             WHERE gidnumber=$gidnumber" );
           $sql="INSERT INTO project_details 
	     (id,longname,addquota,addmailquota,maxmembers,
              creationdate,sophomorixstatus,joinable,mailalias,maillist)
	      VALUES
	      ($id,'$p_long_name','$p_add_quota',$p_add_mail_quota,
               $p_max_members,'$pg_timestamp','$p_status',$p_join,
               $p_mailalias,$p_maillist)";
           if($Conf::log_level>=3){
              print "SQL: $sql\n";
           }
           $dbh->do($sql);
        } else {
           print "Project $project doesnt exist, use --create to create it. \n";
	   exit;
        }
    } else {
        if ($create==0){
           # update
           $sql="UPDATE project_details 
                 SET longname='$p_long_name', addquota='$p_add_quota',
                     addmailquota=$p_add_mail_quota, 
                     maxmembers='$p_max_members',sophomorixstatus='$p_status',
                     joinable=$p_join,mailalias='$p_mailalias',
                     maillist='$p_maillist'
                 WHERE id = $old_id";
           if($Conf::log_level>=3){
              print "SQL: $sql\n";
           }
           $dbh->do($sql);
        } else {
           print "\nProject $project exist already. \n";
           print "If you want to update $project do NOT use --create. \n\n";
	   exit;
        }
    }

    print "2) Exchange Directories:\n";

    my %users_to_add=();

    my %users_to_keep=();

    my %users_to_keep_groupmembers=();
    my %users_to_keep_projectmembers=();

    my %admins_to_add=();
    my %projects_to_add=();

    my @users_to_add=();
    my @admins_to_add=();
    my @groups_to_add=();
    my @projects_to_add=();

    my $old_users="";
    my @old_users=();
    my @old_admins=();
    my @old_members_by_option=();
    my @old_groups=();
    my @old_projects=();

    my %seen=();

    my @new_members=();
    my @new_admins=();
    my @new_members_by_option=();
    my @new_groups=();
    my @new_projects=();

    &Sophomorix::SophomorixBase::provide_project_files($project);

    # get old values
    # users and admins
    @old_users=&fetchusers_from_project($project);
    @old_admins=&fetchadmins_from_project($project);
    @old_members_by_option=&fetchmembers_by_option_from_project($project);
    @old_groups=&fetchgroups_from_project($project);
    @old_projects=&fetchprojects_from_project($project);

    # Adding all users/admins/groups/projects from options to lists
    if (defined $p_members){
        @new_members=split(/,/,$p_members);
    } else {
	@new_members=@old_users;
    }
     if (defined $p_admins){
        @new_admins=split(/,/,$p_admins);
    } else {
        @new_admins=@old_admins;          
    }
     if (defined $p_members){
        @new_members_by_option=split(/,/,$p_members);
    } else {
        @new_members_by_option=@old_members_by_option;          
    }
     if (defined $p_groups){
        @new_groups=split(/,/,$p_groups);
    } else {
        @new_groups=@old_groups;          
    }
    if (defined $p_projects){
        @new_projects=split(/,/,$p_projects);
    } else {
        @new_projects=@old_projects;          
    }

    # Add the users in the groups
    foreach my $group (@new_groups){
        my @new_users_pri=();
        # check if group must be skipped
        # A) group seen
        if (exists $seen{$group}){
	    print "Aaaargh, I have seen group $group! \n",
                  "Are you using recursive/multiple groups ...?\n";
            next;
        }
        # remember the group
        $seen{$group}="seen";
        # B) avoid circles
        if ($group eq $project){
            print "It's nonsense to have a group as its MemberGroups\n",
	          "... skipping $group as MemberGroups in $project\n";
	    next;
        }

        # select the primary users
        @new_users_pri=&fetchstudents_from_adminclass($group);

        if($Conf::log_level>=2){
             &Sophomorix::SophomorixBase::print_list_column(4,
                "primary members of $group",@new_users_pri);
        }

        # removing doubles
        foreach my $user (@new_users_pri){        
           if (not exists $users_to_add{$user}){
       	      $users_to_add{$user}="$group(primary)";
           }
           # this users must be kept because of their groupmembership
           if (not exists $users_to_keep_groupmembers{$user}){
       	      $users_to_keep_groupmembers{$user}="$group(primary)";
           }
        }
    }

    # Add the users in the projects
    foreach my $m_project (@new_projects){
        my @new_users_sec=();

        # check if project must be skipped
        # A) project seen
        if (exists $seen{$m_project}){
	    print "Aaaargh, I have seen group $m_project! \n",
                  "Are you using recursive/multiple groups ...?\n";
            next;
        }
        # remember the project
        $seen{$m_project}="seen";
        # B) avoid circles
        if ($m_project eq $project){
            print "It's nonsense to have a group as its MemberGroups\n",
	          "... skipping $m_project as MemberGroups in $project\n";
	    next;
        }
        # select the secondary users (admins and users)
        @new_users_sec=&fetchusers_from_project($m_project);

        if($Conf::log_level>=2){
             &Sophomorix::SophomorixBase::print_list_column(4,
                "secondary members of $m_project",@new_users_sec);
        }

        # removing doubles
        foreach my $user (@new_users_sec){        
           if (not exists $users_to_add{$user}){
       	      $users_to_add{$user}="$m_project(secondary)";
           }
           if (not exists $users_to_keep_projectmembers{$user}){
       	      $users_to_keep_projectmembers{$user}="$m_project(secondary)";
           }
        }
    }

    foreach my $memb (@new_members){
	print "adding $memb as member_by_option\n";
	$users_to_add{ $memb }="member_by_option";
    }

    foreach my $memb (@new_admins){
	print "adding $memb as admin\n";
	$users_to_add{ $memb }="projectadmin";
    }

    foreach my $memb (@new_members_by_option){
	print "adding $memb as member by option\n";
	$users_to_add_by_option{ $memb }="by_option";
    }

    if($Conf::log_level>=2){
       print "\nThis users will be members of project $project\n";
       printf "   %-20s %-20s \n","User:","Group:";
       print "------------------------------------------------------------\n";
       while (($k,$v) = each %users_to_add){
          printf "   %-20s %-20s \n",$k,$v;
       }
       print "------------------------------------------------------------\n";
    }

    # remember this list (all of this users must be kept)
    %users_to_keep = %users_to_add;    

    foreach my $admin (@new_admins){
	$admins_to_add{ $admin }="";
    }
    foreach my $group (@new_groups){
	$groups_to_add{ $group }="";
    }
    foreach my $project (@new_projects){
	$projects_to_add{ $project }="";
    }
    &db_disconnect($dbh);

    print "3) Managing memberships:\n";
    if($Conf::log_level>=2){
       print "What to compare:\n";
       print "   Old users: @old_users\n";
       print "   Old admins: @old_admins\n";
       print "   Old groups: @old_groups\n";
       print "   Old projects: @old_projects\n";
       print "   New members: @new_members\n";
       print "   New admins: @new_admins\n";
       print "   New groups: @new_groups\n";
       print "   New projects: @new_projects\n";

    }

    print "What to do:\n";

    # users
    # ========================================
    # calculating which users to add
    foreach my $user (@old_users){
       if ($longname_changed==1){
            &Sophomorix::SophomorixBase::remove_share_link($user,
                                       $project,$old_long_name);
            &Sophomorix::SophomorixBase::create_share_link($user,
                                       $project,$p_long_name);
            &Sophomorix::SophomorixBase::remove_share_directory($user,
                                       $project,$old_long_name);
            &Sophomorix::SophomorixBase::create_share_directory($user,
                                       $project,$p_long_name);

       }
       if (exists $users_to_add{$user}){
          # remove user from users_to_add
          if($Conf::log_level>=3){
             print "     User $user does not need to be added\n";
	  }
          delete $users_to_add{$user}; 
       } elsif (not exists $users_to_add{$user}) {
         # remove user
          if($Conf::log_level>=3){
            print "     User $user has left Project $project,",
                  " removing $user\n";
         }
         #system("gpasswd -d $user $project");
	 &deleteuser_from_project($user,$project,1);
         &Sophomorix::SophomorixBase::remove_share_link($user,
                                         $project,$p_long_name);
         # This removes the shares, if they exist
         # (They do not all exist as students but teachers)
         &Sophomorix::SophomorixBase::remove_share_directory($user,
                                         $project,$p_long_name);

       } 
    }    
    
    while (my ($user) = each %users_to_add){
       #print "$user must be added\n";
       push @users_to_add, $user;
    }
    # sorting
    @users_to_add = sort @users_to_add;
    print "  Users to add: @users_to_add\n";
    # adding the users
    foreach my $user (@users_to_add) {
       if ($user eq "root"){next;}
       &adduser_to_project($user,$project);
       # create a link
       &Sophomorix::SophomorixBase::create_share_link($user,
                                        $project,$p_long_name);
       # create directories 
       &Sophomorix::SophomorixBase::create_share_directory($user,
                                        $project,$p_long_name);
    }


    # admins
    # ========================================
    # calculating which users to add as admins
    foreach my $user (@old_admins){
       if (exists $admins_to_add{$user}){
          # remove user from admins_to_add
          if($Conf::log_level>=3){
             print "     User $user does not need to be added as admin\n";
	  }
          delete $admins_to_add{$user}; 
       } elsif (not exists $admins_to_add{$user}) {
         # remove user
          if($Conf::log_level>=3){
            print "     Admin $user has left Project $project,",
                  " removing $user\n";
         }
         #system("gpasswd -d $user $project");
	 &deleteadmin_from_project($user,$project);
         &Sophomorix::SophomorixBase::remove_share_link($user,
                                          $project,$p_long_name);
         &Sophomorix::SophomorixBase::remove_share_directory($user,
                                          $project,$p_long_name);
       } 
    }    
    
    while (my ($user) = each %admins_to_add){
       #print "$user must be added\n";
       push @admins_to_add, $user;
    }
    # sorting
    @admins_to_add = sort @admins_to_add;
    print "  Users to add as admins: @admins_to_add\n";
    # adding the users
    foreach my $user (@admins_to_add) {
       if ($user eq "root"){next;}
       &addadmin_to_project($user,$project);
       # create a link
       &Sophomorix::SophomorixBase::create_share_link($user,
                                         $project,$p_long_name);
       # create directories
       &Sophomorix::SophomorixBase::create_share_directory($user,
                                        $project,$p_long_name);
    }


    # groups
    # ========================================
    # calculating which groups to add to project
    foreach my $group (@old_groups){
       if (exists $groups_to_add{$group}){
          # remove group from groups_to_add
          if($Conf::log_level>=3){
             print "     Group $group does not need to be added\n";
	  }
          delete $groups_to_add{$group}; 
       } elsif (not exists $groups_to_add{$group}) {
         # remove user
          if($Conf::log_level>=3){
            print "     Group $group has left Project $project,",
                  " removing $group\n";
         }
	 my @users_to_remove = fetchstudents_from_adminclass($group);
	 print "  Removing users of group ${group}:\n";
	 foreach my $user (@users_to_remove){
             # check if user must be kept
             if (exists $users_to_keep_projectmembers{$user}){
                 print "   Not deleting $user (is still member/admin ",
                       "in project $users_to_keep_projectmembers{$user})\n";
                 next;
             }
             &deleteuser_from_project($user,$project,1);
             &Sophomorix::SophomorixBase::remove_share_link($user,
                                          $project,$p_long_name);
             &Sophomorix::SophomorixBase::remove_share_directory($user,
                                          $project,$p_long_name);
         }
	 &deletegroup_from_project($group,$project);
       } 
    }    
    
    while (my ($group) = each %groups_to_add){
       print "$group must be added\n";
       push @groups_to_add, $group;
    }
    # sorting
    @groups_to_add = sort @groups_to_add;
    print "  Groups to add: @groups_to_add\n";
    # adding the groups
    foreach my $group (@groups_to_add) {
       	if ($group ne $project){
           &addgroup_to_project($group,$project);
        } else {
            print "WARNING: Not adding $group to itself!\n";
        }

    }


    # projects
    # ========================================
    # calculating which m_projects to add 
    foreach my $m_project (@old_projects){
       if (exists $projects_to_add{$m_project}){
          # remove m_project from projectss_to_add
          if($Conf::log_level>=3){
             print "     Project $m_project does not need to be added\n";
	  }
          delete $projects_to_add{$m_project}; 
       } elsif (not exists $projects_to_add{$m_project}) {
         # remove m_project
          if($Conf::log_level>=3){
            print "     Project $m_project has left Project $project,",
                  " removing $m_project\n";
         }
         
         # select only members, not admins
	 my @users_to_remove = &fetchmembers_from_project($m_project);
	 print "  Removing users of project ${project}:\n";
	 foreach my $user (@users_to_remove){
             # check if user must be kept
             if (exists $users_to_keep_projectmembers{$user}){
                 print "   Not deleting $user (is still member/admin ",
                       "in project $users_to_keep_projectmembers{$user})\n";
                 next;
             }
             if (exists $users_to_keep_groupmembers{$user}){
                 print "   Not deleting $user (is still member/admin ",
                       "in adminclass $users_to_keep_groupmembers{$user})\n";
                 next;
             }

             &deleteuser_from_project($user,$project,1);
             &Sophomorix::SophomorixBase::remove_share_link($user,
                                          $project,$p_long_name);
             &Sophomorix::SophomorixBase::remove_share_directory($user,
                                          $project,$p_long_name);
         }
	 print "  Removing project ${project}:\n";
	 &deleteproject_from_project($m_project,$project);
       } 
    }    
    
    while (my ($m_project) = each %projects_to_add){
       push @projects_to_add, $m_project;
    }
    # sorting
    @projects_to_add = sort @projects_to_add;
    print "  Projects to add as members: @projects_to_add\n";
    # adding the projects
    foreach my $m_project (@projects_to_add) {
	if ($m_project ne $project){
            &addproject_to_project($m_project,$project);
        } else {
            print "WARNING: Not adding $project to itself!\n";
        }
    }


    { # can be  be a function later
    print "updating projects_members table (users by option)\n";
    my $dbh=&db_connect();
    my ($id)= $dbh->selectrow_array( "SELECT id
                                      FROM groups 
                                      WHERE gid='$project'
                                      ");
    # delete all entries
    my $sql="DELETE FROM projects_members 
             WHERE projectid=$id 
            ";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
 
    # add entries anew
    while(my ($user, $value) = each(%users_to_add_by_option)) {
        # do something with $key and $value
        my ($uidnumber)= $dbh->selectrow_array( "SELECT uidnumber 
                                         FROM posix_account 
                                         WHERE uid='$user'");
        if (defined $uidnumber){
        print "$user($uidnumber) must be added to project($id) by option\n";
        my $sql="INSERT INTO projects_members
                    (projectid,memberuidnumber)
	             VALUES
	            ('$id','$uidnumber')";	
        if($Conf::log_level>=3){
            print "\nSQL: $sql\n";
        }
        $dbh->do($sql);
        } else {
            print "WARNING: $user nonexisting in postgres, ",
                  "not adding user to project (ldap)\n";
        }
    }
    &db_disconnect($dbh);
    } # end can be a function later
}


sub remove_project  {
    # this removes ONLY entry in project_details
    # and the share, tasks
    # to remove group see remove_class_db_entry
    my ($project) = @_;
    # project id holen
    my $dbh=&db_connect();
    my ($id)= $dbh->selectrow_array( "SELECT id
                                         FROM groups 
                                         WHERE gid='$project'
                                        ");
    # project_details löschen
    my $sql="DELETE FROM project_details 
             WHERE id=$id; 
             ";	
    if($Conf::log_level>=3){
       print "\nSQL: $sql\n";
    }
    $dbh->do($sql);
    &db_disconnect($dbh);

    # remove share,task,... files    
    &Sophomorix::SophomorixBase::remove_project_files($project);
}




=head2 FUNCTIONS

=head3 Searching

=over 4

=cut


=pod

=item I<linie()>

Creates a line.

=cut


# searches the user database and others for a user

# this must be implemented completely new
# because it searches in the lines of user.db


sub search_user {
  # database dependent
  my ($string,$auth) = @_;
  my $str="'\%$string\%'";

  my ($class,$gec_user,$login,$first_pass,$birth,$unid,
      $subclass,$status,$tol,$deact,$ex_admin,$acc_type,$quota)=();

  my ($loginname_passwd,$passwort,$uid_passwd,$gid_passwd,
     $quota_passwd,$name_passwd,$gcos_passwd,$home,$shell)=();

  my $group_string="";
  my @group_list=();
  my $pri_group_string="";
  my $grp_string="";
  my $home_ex="---";

  &Sophomorix::SophomorixBase::titel("I'm looking for $str in postgresql ...");
  my $dbh=&db_connect();

  my $sql="";

  # select the columns that i need
  my $sth= $dbh->prepare( "SELECT DISTINCT uid, firstname, surname, 
                            loginshell, birthday, adminclass, exitadminclass, 
                            unid, subclass, creationdate,tolerationdate, 
                            deactivationdate, sophomorixstatus,
                            gecos, homedirectory, firstpassword, quota, 
                            mailquota, sambaacctflags, sambahomepath, 
                            sambahomedrive, sambalogonscript, 
                            sambaprofilepath, usertoken, scheduled_toleration 
                         FROM userdata
                         WHERE uid LIKE $str
                            OR firstname LIKE $str
                            OR surname LIKE $str
                            OR gecos LIKE $str
                            OR displayname LIKE $str" );
  $sth->execute();

  my $array_ref = $sth->fetchall_arrayref();

  foreach my $row (@$array_ref){
       my $gcos_diff="";

       my ($login,
           $firstname,
           $surname,
           $loginshell,
           $birthday_pg,
           $admin_class,
           $exit_admin_class,
           $unid,
           $subclass,
           $cre,
           $toleration_date_pg,
           $deactivation_date_pg,
           $status,
           $gecos,
           $home,
           $first_pass,
           $quota,
           $mailquota,
           $sambaacctflags, 
           $sambahomepath,
           $sambahomedrive,
           $sambalogonscript,
           $sambaprofilepath, 
           $usertoken,
           $scheduled_toleration,
           ) = @$row;

       my $birthday=&date_pg2perl($birthday_pg);
       my $tol=&date_pg2perl($toleration_date_pg);
       my $deact=&date_pg2perl($deactivation_date_pg);
       my $sched_del=&date_pg2perl($scheduled_toleration);

       # Gruppen-Zugehoerigkeit
       $pri_group_string="";
       $grp_string="";
       @group_list=&Sophomorix::SophomorixPgLdap::pg_get_group_list($login);
       $pri_group_string=$group_list[0];

       # standard Values for nonsophomorix users
       if (not defined $admin_class){$admin_class=""}
       if (not defined $first_pass){$first_pass=""}
       if (not defined $cre){$cre=""}

       my ($auth_name,$auth_passwd,$auth_uid,$auth_gid,$auth_quota,
           $auth_comment,$auth_gcos,$auth_dir,$auth_shell);

       if ($auth==1){
          &Sophomorix::SophomorixBase::titel("Querying ldap ...");
          ($auth_name,$auth_passwd,$auth_uid,$auth_gid,$auth_quota,$auth_comment,
           $auth_gcos,$auth_dir,$auth_shell) = getpwnam($login);
	  print "$auth_gcos \n";
       }

       if (defined $login){
	     print "($login exists in the system) \n";
       } else {
	     print "(ERROR: $login is not in the system) \n";
       }
       print "=======================================";
       print "=======================================\n";

       printf "  AdminClass         : %-45s %-11s\n",$admin_class,$login;
       printf "  PrimaryGroup       : %-45s %-11s\n",$pri_group_string,$login;

       foreach my $gr (@group_list){
	   $grp_string= $grp_string." ".$gr;
       }

       if ($auth==1){
	   if ($gecos eq $auth_gcos){
               $gcos_diff="*";
           } else {
               $gcos_diff="?";
           }
       }

       printf "  SecondaryGroups    :%-46s %-11s\n",$grp_string,$login;
       printf "  Gecos              : %-44s %-1s%-11s\n", 
               $gecos,$gcos_diff,$login;
       if (-e $home){
          $home_ex=$home." (exists)";
       } else {
          $home_ex=$home."  (ERROR: non-existing)";
       }
       if (defined $home){
          printf "  Home               : %-45s %-11s\n",$home_ex,$login;
       }

       if (defined $loginshell){
          printf "  loginShell         : %-45s %-11s\n",$loginshell,$login;
       }

       if($Conf::log_level>=3){
           print "Compare pg to LDAP attributes:\n";
           &compare_pg_with_ldap($login);
       } else {
           my $err_num = &compare_pg_with_ldap($login);
           printf "Comparing ldap with pg showed $err_num errors%-30s %-11s\n",
                 "",$login;
       }

       print "Sophomorix (Database Values):\n";     
       if (defined $usertoken){
          printf "  Usertoken          : %-45s %-11s\n",$usertoken,$login;
       }

       printf "  FirstPassword      : %-45s %-11s\n",$first_pass,$login;
       printf "  Birthday           : %-45s %-11s\n",$birthday,$login;

       if (defined $unid){
          printf "  Unid               : %-45s %-11s\n",$unid,$login;
       }

       if (defined $subclass){
	  printf "  SubClass           : %-45s %-11s\n",$subclass,$login;
       }

       if (defined $status){
	  printf "  Status             : %-45s %-11s\n",$status,$login;
       }

       if (defined $tol){
          printf "  CreationDate       : %-45s %-11s\n",$cre,$login;
       }

       if (defined $tol){
          printf "  TolerationDate     : %-45s %-11s\n",$tol,$login;
       }

       if (defined $deact){
          printf "  DeactivationDate   : %-45s %-11s\n",$deact,$login;
       }

       if (defined $sched_del){
          printf "  ScheduledToleration: %-45s %-11s\n",$sched_del,$login;
       }

       if (defined $ex_admin){
	  printf "  ExitAdminClass     : %-45s %-11s\n",$ex_admin,$login;
       }

       if (defined $acc_type){
	  printf "  AccountType        : %-45s %-11s\n",$acc_type,$login;
       }


       if($Conf::use_quota eq "yes"){
          if (defined $quota){
	     printf "  Quota (MB)         : %-45s %-11s\n",$quota,$login;
          } else {
	     print  "  Quota (MB)         : --- \n";
          }
       }

       if (defined $mailquota){
	  printf "  MailQuota (MB)     : %-45s %-11s\n",$mailquota,$login;
       }


       if($Conf::use_quota eq "yes" and $Conf::log_level>=2){
          if (-e "/usr/bin/quota"){
             print "Showing values of quota in the system:\n";
             # -l show only local quota, no nfs
             # -v show quota on unused filesystems          
             #system("quota -l -v $login");
             my $show=`quota -l -v $login`;
	     print "  "; # indent output of following command
             $show =~ s/\n  /\n/g; # remove indent partially
             $show =~ s/\/dev/   \/dev/g; # remove indent partially
             print $show;
          }
       }



       if($Conf::log_level>=2){
           print "Asking the Cyrus/Imap server:\n";
           my $imap=&Sophomorix::SophomorixBase::imap_connect("localhost",${DevelConf::imap_admin},1);
           my $imap_user="user.".$login;
           my @mail_quota=&Sophomorix::SophomorixBase::imap_fetch_mailquota($imap,$imap_user,1,1);
           &Sophomorix::SophomorixBase::imap_disconnect($imap,1);
           if (not defined $mail_quota[1]){
	       print "BNO\n";
	       @mail_quota=("---","---","---");
           }
           printf "  Cyrus Account      : %-45s %-11s\n",$mail_quota[0],$login;
           printf "  MailQuota/Cyrus(MB): %-45s %-11s\n",$mail_quota[2],$login;
           printf "  Used               : %-45s %-11s\n",$mail_quota[1],$login;

       }

       print "Samba:\n";

       if (defined $sambaacctflags){
          printf "  sambaAcctFlags     : %-45s %-11s\n",$sambaacctflags,$login;
       }

       if (defined $sambahomepath){
          printf "  sambaHomePath      : %-45s %-11s\n",$sambahomepath,$login;
       }

       if (defined $sambahomedrive){
          printf "  sambaHomeDrive     : %-45s %-11s\n",$sambahomedrive,$login;
       }

       if (defined $sambalogonscript){
          printf "  sambaLogonScript   : %-45s %-11s\n",$sambalogonscript,$login;
       }

       if (defined $sambaprofilepath){
          printf "  sambaProfilePath   : %-45s %-11s\n",$sambaprofilepath,$login;
       }

       # webmin, database independent
       #&Sophomorix::SophomorixBase::print_user_webmin_data($login);

       if($Conf::log_level>=2){
          # history, database independent
          print "History of $login:\n";
          &Sophomorix::SophomorixBase::get_user_history($login);
          print "Mail forwarding of $login:\n";
          &Sophomorix::SophomorixBase::print_forward($login, $home);
       }
       print "\n";

       ($class,$gec_user,$login,$first_pass,$birth,$unid,
        $subclass,$status,$tol,$deact,$ex_admin,$acc_type,$quota)=(
        "","","","","","","","","","","","");
  }
}




=pod

=item  I<backup_sys_database()>

Makes a backup of the sophomorix user database

=cut

# this function can be left empty so far

sub backup_user_database {
    my ($time, $string) = @_;
    &titel("Dumping database ldap before I modify it");
    &do_falls_nicht_testen(
      "pg_dump --format=p -U ldap --file=${DevelConf::log_pfad}/${time}.ldap-${string} ldap",
      "chmod 600 ${DevelConf::log_pfad}/${time}.ldap-${string}",
# This is done by a cronjob now
#      "cd  ${DevelConf::log_pfad}; gzip -f ${time}.ldap-${string}"
    );
}


=pod

=item  I<get_first-password(login)>

Returns the FirstPassword of the user login

=cut


# query the datadase for a users initial password 
sub get_first_password {
   my ($login) = @_;
   my $dbh=&db_connect();
   my $sql="";
   $sql="SELECT firstpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($first_pass)= $dbh->selectrow_array($sql);
   print "   First password: $first_pass\n";
   return $first_pass;
}




=pod

=item  I<check_sophomorix_user(login,uidnumber)>

Returns 1, if login is in the sophomorix database, and if it has
uidnumber uidnumber.

=cut


sub check_sophomorix_user {
  my ($login,$id) = @_;
  my $result=0;
  my $dbh=&db_connect();
  my $sql="";
  $sql="SELECT id,uidnumber FROM userdata WHERE uid='$login'";
  if($Conf::log_level>=3){
     print "\nSQL: $sql\n";
  }
  my ($uid,$uidnumber)= $dbh->selectrow_array($sql);
  if (defined $uidnumber and defined $id and $uidnumber!=$id){
      print "$login ($uidnumber) exists but uidnumber is not $id\n";
      $result=0;
  } elsif (defined $uid) {
      $result=1;
  } else {
      $result=0;
  }
  &db_disconnect($dbh);
  return $result;
}







sub check_sophomorix_user_oldstuff {
  my ($username) = @_;
  my $result=0;
  open(PASSPROT, "$DevelConf::dyn_config_pfad/user_db");
  while(<PASSPROT>) {
      chomp(); # Returnzeichen abschneiden
      s/\s//g; # Spezialzeichen raus
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      my ($gruppe, $nax, $login, $pass) = split(/;/);
      if ($username eq $login) {
        $result=1;
      }
  }
  close(PASSPROT);
  return $result;
}




sub show_project_list {
    print "-----------------+----------+-----+----+-+-",
          "+-+-+--------------------------------\n";
    printf "%-17s|%9s |%4s |%3s |%1s|%1s|%1s|%1s| %-20s \n",
           "Name","addquota","AMQ","MM","A","L","S","J","(Longname)";
    print "-----------------+----------+-----+----+-+-",
          "+-+-+--------------------------------\n";
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid,addquota,addmailquota,
                                    longname,maxmembers,sophomorixstatus,
                                    joinable,mailalias,maillist 
                             FROM projectdata 
                             ORDER BY gid");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        my $addquota=${$array_ref}[$i][1];
        my $addmailquota=${$array_ref}[$i][2];
        my $longname=${$array_ref}[$i][3];
        my $maxmembers=${$array_ref}[$i][4];
        my $status=${$array_ref}[$i][5];
        my $joinable=${$array_ref}[$i][6];
        my $mailalias=${$array_ref}[$i][7];
        my $maillist=${$array_ref}[$i][8];

        if (not defined $gid){
	    $gid="";
        }
        if (not defined $addquota){
	    $addquota="";
        }
        if (not defined $addmailquota){
	    $addmailquota="";
        }
        if (not defined $longname){
	    $longname="";
        }
        if (not defined $maxmembers){
	    $maxmembers="";
        }
        if (not defined $mailalias){
	    $mailalias="";
        }
        if (not defined $maillist){
	    $maillist="";
        }
        if (not defined $status){
	    $status="";
        }
        if (not defined $joinable){
	    $joinable="";
        }
        printf "%-17s|%9s |%4s |%3s |%1s|%1s|%1s|%1s| %-20s\n",$gid,
                $addquota,$addmailquota,$maxmembers,$mailalias,
                $maillist,$status,$joinable,$longname;
        $i++;
    }   
    print "-----------------+----------+-----+----+-+-",
          "+-+-+--------------------------------\n";
    print "(AMQ=addmailquota, MM=maxmembers, A=mailalias,",
          " L=mailist, S=status, J=joinable)\n";
    print "$i projects\n";
    &db_disconnect($dbh);
}






sub show_class_list {
    print "---------------+----------+-----",
          "+-+-+--------------------+---------------------\n";
    printf "%-14s | %8s |%4s |%1s|%1s| %-19s| %-20s\n","AdminClass",
           "Quota", "MQ","A","L","SchoolType","Department";
    print "---------------+----------+-----",
          "+-+-+--------------------+---------------------\n";
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid,quota,mailquota,mailalias,
                                    maillist,schooltype,department
                             FROM classdata
                             WHERE (type='adminclass' OR type='teacher')
                             ORDER BY gid" );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        my $quota=${$array_ref}[$i][1];
        my $mailquota=${$array_ref}[$i][2];
        my $mailalias=${$array_ref}[$i][3];
        my $maillist=${$array_ref}[$i][4];
        my $schooltype=${$array_ref}[$i][5];
        my $department=${$array_ref}[$i][6];
        if (not defined $gid){
	    $gid="";
        }
        if (not defined $quota or $quota eq "quota"){
	    $quota="";
        }
        if (not defined $mailquota or $mailquota==-1){
	    $mailquota="";
        }
        if (not defined $schooltype){
	    $schooltype="";
        }
        if (not defined $department){
	    $department="";
        }
#        if (not ($gid eq "speicher" or $gid eq "dachboden")){
        if (not ($gid eq "attic")){
        printf "%-15s|%10s|%4s |%1s|%1s| %-19s| %-18s\n",$gid,
                $quota,$mailquota,$mailalias,$maillist,
                $schooltype,$department;
        }
        $i++;
    }   
    print "---------------+----------+-----",
          "+-+-+--------------------+---------------------\n";
    print "$i classes    (MQ=MailQuota, A=Mailalias,",
          " L=Mailist)\n";
    &db_disconnect($dbh);
}




sub show_class_teacher_list {
    print "\n";
    my @classes=&fetchadminclasses_from_school();
    print "+--------------+----------------------",
          "---------------------------------------+\n";    
    print "| Classes      | Member Teachers      ",
          "                                       |\n";
    foreach my $class (@classes){
        my @teachers=&fetchadmins_from_adminclass($class);
        my $count=0;

        if ($#teachers+1>0){
            print "+--------------+----------------------",
                  "---------------------------------------+\n";    
        }

        while ($#teachers+1>0){
	   $count++;
           my @new = splice(@teachers, 0, 5);
           while ($#new<4){
	       push @new,"";
           }
           if ($count==1){
               printf "| %-12s | %-12s%-12s%-12s%-12s%-12s|\n",
                      $class,@new;
           } else {
               printf  "| %12s | %-12s%-12s%-12s%-12s%-12s|\n",
                      $class,@new;
           }
        }
    }
    print "+--------------+----------------------",
          "---------------------------------------+\n";    
}




sub show_teacher_class_list {
    print "\n";
    my @teachers=&fetchusers_from_adminclass(${DevelConf::teacher});
    foreach my $teacher (@teachers){
        my @classes=&fetch_my_adminclasses($teacher);
 
        my $count=0;

        if ($#classes+1>0){
            print "+--------------+----------------------",
                  "---------------------------------------+\n";    
        }

        while ($#classes+1>0){
	   $count++;
           my @new = splice(@classes, 0, 5);
           while ($#new<4){
	       push @new,"";
           }
           if ($count==1){
               printf "| %-12s | %-12s%-12s%-12s%-12s%-12s|\n",
                      $teacher,@new;
           } else {
               printf  "| %12s | %-12s%-12s%-12s%-12s%-12s|\n",
                      $teacher,@new;
           }
        }
    }
    print "+--------------+----------------------",
          "---------------------------------------+\n";    
}




sub fetch_used_subclasses {
    my ($class) = @_;
    my @used_subclasses;
    my $dbh=&db_connect();

    my $sub_a = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                        FROM userdata 
                                        WHERE (subclass='A'
                                          AND gid='$class')
                                       " );
    my $sub_b = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                        FROM userdata 
                                        WHERE (subclass='B'
                                          AND gid='$class')
                                       " );
    my $sub_c = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                        FROM userdata 
                                        WHERE (subclass='C'
                                          AND gid='$class')
                                      " );
    my $sub_d = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                        FROM userdata 
                                        WHERE (subclass='D'
                                          AND gid='$class')
                                       " );

    if ($sub_a > 0){
        push @used_subclasses, "A";
    }
    if ($sub_b > 0){
        push @used_subclasses, "B";
    }
    if ($sub_c > 0){
        push @used_subclasses, "C";
    }
    if ($sub_d > 0){
        push @used_subclasses, "D";
    }

    &db_disconnect($dbh);
    return @used_subclasses;
}




sub show_subclass_list {
    print "The following adminclasses have members in subclasses:\n\n";
    printf "%-20s | %5s |  %1s  |  %1s  |  %1s  |  %1s  |\n",
           "AdminClass","Total","A","B","C","D";
    print "---------------------+-------+-----+-----+-----+-----+\n";

    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid,COUNT(*) AS num
                             FROM userdata 
                             WHERE (subclass='A'
                                 OR subclass='B'
                                 OR subclass='C'
                                 OR subclass='D')
                                 GROUP BY gid" );
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    my $sub_a=0;
    my $sub_b=0;
    my $sub_c=0;
    my $sub_d=0;
    my $total=0;

    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        my $total=${$array_ref}[$i][1];

        $sub_a = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                     FROM userdata 
                                     WHERE (subclass='A'
                                       AND gid='$gid')
                                    " );
        $sub_b = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                     FROM userdata 
                                     WHERE (subclass='B'
                                       AND gid='$gid')
                                    " );
        $sub_c = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                     FROM userdata 
                                     WHERE (subclass='C'
                                       AND gid='$gid')
                                    " );
        $sub_d = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                     FROM userdata 
                                     WHERE (subclass='D'
                                       AND gid='$gid')
                                    " );
        printf "%-20s |  %3s  | %3s | %3s | %3s | %3s |\n",
        $gid,$total,$sub_a,$sub_b,$sub_c,$sub_d;

        $i++;
    }   
    print "---------------------+-------+-----+-----+-----+-----+\n";
    &db_disconnect($dbh);
}






sub show_project {
    my ($project) = @_;
    my ($longname,$addquota,$add_mail_quota,
        $status,$join,$time,$max_members,
        $mailalias,$maillist)=&fetchinfo_from_project($project);
    if (defined $longname){
       print "Project:             $project\n";
       print "   LongName:         $longname\n";
       print "   AddQuota:         $addquota MB\n";
       print "   AddMailQuota:     $add_mail_quota MB\n";
       print "   MailAlias:        $mailalias\n";
       print "   MailList:         $maillist\n";
       print "   SophomorixStatus: $status\n";
       print "   Joinable:         $join\n";
       print "   MaxMembers:       $max_members\n";
       print "   CreationTime:     $time\n";
    }

    my @admins=&fetchadmins_from_project($project);
    @admins = sort @admins;
    &Sophomorix::SophomorixBase::print_list_column(4,
       "Admins of $project",@admins);
    print "\n";
    # show only by_option members, not admins (admins are shown earlier)
    my @user_bo=&fetchmembers_by_option_from_project($project);
    @user_bo = sort @user_bo;
    &Sophomorix::SophomorixBase::print_list_column(4,
       "Members by_option from $project",@user_bo);
    print "\n";
    my @groups=&fetchgroups_from_project($project);
    @groups = sort @groups;
    &Sophomorix::SophomorixBase::print_list_column(4,
      "MemberGroups of $project",@groups);
    print "\n";
    my @pro=&fetchprojects_from_project($project);
    @pro = sort @pro;
    &Sophomorix::SophomorixBase::print_list_column(4,
      "MemberProjects of $project",@pro);

    if($Conf::log_level>=2){
       print "\n";
       # show all members, not admins (admins are shown earlier)
       my @user=&fetchmembers_from_project($project);
       @user = sort @user;
       &Sophomorix::SophomorixBase::print_list_column(4,
          "All Members  from $project",@user);
       }
}



sub dump_all_projects {
    my ($file) = @_;
    &titel("dumping all projects to $file");
    if (-e $file){
        print "ERROR: File $file exists. I will not overwrite!\n";
        exit;
    }
    my @projects=&fetchprojects_from_school();

    open(DUMP, ">$file");
    foreach my $project (@projects){
        print "Dumping project:  $project \n";
        my ($longname,$addquota,$add_mail_quota,$status,$join,$time,
         $max_members,$mailalias,$maillist,$id,
         $type,$schooltype,$department,
         $creationdate,$enddate,$tolerationdate,$deactivationdate
         )=&fetchinfo_from_project($project);

        my @admins=&fetchadmins_from_project($project);
        @admins = sort @admins;
        my $admins=join(",",@admins);

        my @users=&fetchmembers_by_option_from_project($project);
        @users = sort @users;
        my $users=join(",",@users);

        my @groups=&fetchgroups_from_project($project);
        @groups = sort @groups;
        my $groups=join(",",@groups);

        my @pro=&fetchprojects_from_project($project);
        @pro = sort @pro;
        my $pro=join(",",@pro);

        print DUMP "[$project]\n";
        print DUMP "  ${project}.addmailquota=${add_mail_quota}\n";
        print DUMP "  ${project}.addquota=${addquota}\n";
        print DUMP "  ${project}.admins=${admins}\n";
        print DUMP "  ${project}.creationdate=${creationdate}\n";
        print DUMP "  ${project}.deactivationdate=${deactivationdate}\n";
        print DUMP "  ${project}.department=${department}\n";
        print DUMP "  ${project}.enddate=${enddate}\n";
        print DUMP "  ${project}.id=${id}\n";
        print DUMP "  ${project}.joinable=${join}\n";
        print DUMP "  ${project}.longname=$longname\n";
        print DUMP "  ${project}.mailalias=${mailalias}\n";
        print DUMP "  ${project}.maillist=${maillist}\n";
        print DUMP "  ${project}.maxmembers=${max_members}\n";
        print DUMP "  ${project}.membergroups=${groups}\n";
        print DUMP "  ${project}.memberprojects=${pro}\n";
        print DUMP "  ${project}.members=${users}\n";
        print DUMP "  ${project}.sophomorixstatus=${status}\n";
        print DUMP "  ${project}.schooltype=${schooltype}\n";
        print DUMP "  ${project}.tolerationdate=${tolerationdate}\n";
        print DUMP "  ${project}.type=${type}\n";
        print DUMP "\n";
    }
    close(DUMP);
}




sub show_room_list {
    my @rooms = &fetchrooms_from_school();
    my $number=0;
    my $sum=0;
    my $dbh=&db_connect();
    print "-----------------+--------------+\n";
    printf "%-16s | %-13s|\n","Room","workstations";
    print "-----------------+--------------+\n";
    foreach my $room (@rooms){
        my $number = $dbh->selectrow_array( "SELECT COUNT(*) AS num
                                             FROM userdata 
                                             WHERE (gid='$room')
                                            " );
        printf "%-16s | %8s     |\n",$room,$number;
        $sum=$sum+$number;
    }
    print "-----------------+--------------+\n";
    printf "%-16s | %8s     |\n","All workstations",$sum;
    print "-----------------+--------------+\n";
    &db_disconnect($dbh);
}





sub smb_user_sid {
    my ($uidnumber,$sid) = @_;
    my $user_sid = 2*$uidnumber+1000;
    $user_sid = "$sid"."-"."$user_sid"; 
    return $user_sid;
}


sub smb_group_sid {
    # when adding a user
    my ($gidnumber,$sid) = @_;
    my $group_sid;
    if ($gidnumber==515){
        $group_sid="$sid"."-"."$gidnumber";
    } else {
        $group_sid=2*$gidnumber+1001;
        $group_sid="$sid"."-"."$group_sid";
    }
    return $group_sid;
}


sub get_smb_sid {
    my $sid_debconf = 
      &Sophomorix::SophomorixBase::get_debconf_value("linuxmuster-base", "sambasid",0);
    my $sid="";
    my $rubbish="";
    if ($sid_debconf eq "0"){
        $sid_string=`net getlocalsid`;
        chomp($sid_string);
        ($rubbish,$sid) = split(/: /,$sid_string);
        return $sid;
    } else {
        return $sid_debconf;
    }
}


sub fetchquota_sum {
    my $quota_fs_num = &Sophomorix::SophomorixBase::get_quota_fs_num();
    my @quota_fs=&Sophomorix::SophomorixBase::get_quota_fs_liste();
    my @quota_sum=();
    foreach my $name (@quota_fs){
        push @quota_sum,0;
    }

    my $dbh=&db_connect();

  
    print "\nQuota Values from database (actual values can differ!):";
    print "\n=======================================================\n\n";

    # mailquota
    my ($mail_sum)= $dbh->selectrow_array( "SELECT SUM(mailquota) 
                                         FROM userdata 
                                            WHERE (mailquota IS NOT NULL 
                                            AND mailquota > 0);
                                        ");

    $mail_sum=int($mail_sum)/1000;
    print "Sum of maximum allowed Mailquota space is\n";
    printf "  %10s GB \n",$mail_sum;

    # filesystem quota
    my $sth= $dbh->prepare( "SELECT uid,quota 
                             FROM userdata
                                WHERE quota IS NOT NULL;
                            ");
    $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    foreach my $row (@$array_ref){
       my ($uid,$quota)=@$row;
	  @qlist=split(/\+/,$quota);
          my $count=0;
          foreach my $value (@qlist){
             $quota_sum[$count]=$quota_sum[$count]+$value; 
             $count++;
          }
    }
    &db_disconnect($dbh);

    # output
    print "\nSum of maximum allowed Quota space is:\n";
    for (my $i=0;$i<=$#quota_fs;$i++){
        #my $string=$quota_sum[$i]/1000;
        $string=int($quota_sum[$i])/1000;
        printf "  %10s GB on %-30s\n",$string ,$quota_fs[$i];
    }
    print "\n";
}










################################################################################
#
# authentication system stuff
#
################################################################################





# change password calling smbldap-passwd interactively
# use Expect; # must be loaded
sub auth_passwd {
    use Expect;
    my ($username,$new_password)=@_;
    my $command = Expect->spawn("/usr/sbin/smbldap-passwd $username")
        or die "Couldn't start program: $!\n";

    if($Conf::log_level>=3){
	print "Running /usr/sbin/smbldap-passwd ${username}:\n";
    } else {
       # prevent the program's output from being shown on our STDOUT
       $command->log_stdout(0);
    }

    # wait 10 seconds
    unless ($command->expect(10, "New password :")) {
        exit;
        # timed out
    }
    print $command "$new_password\n";

    # wait 10 seconds
    unless ($command->expect(10, "Retype new password :")) {
        exit;
        # timed out
    }
    print $command "$new_password\n";

    # if the program will terminate by itself, finish up with
    $command->soft_close( );

    # if the program must be explicitly killed, finish up with
    #$command->hard_close( );
}


sub auth_useradd {
   my ($login,$uid_number,$gecos,$home,$unix_group,
       $sec_groups,$shell,$type,$smb_ldap_homepath,$lastname) = @_; 
   my ($u_home,$u_type,$u_gecos,$u_group,
       $u_uidnumber)=&fetchdata_from_account($login);
   my ($g_type,$g_name,$g_gidnumber)=&pg_get_group_type($unix_group);
   # add entry to seperate ldap
   if (defined $u_uidnumber){
       if ($u_uidnumber eq $uid_number){
           print "Succesfully added $login with uidnumber $u_uidnumber to pg\n";
           print "Adding user to ldap\n";
           # do the ldap stuff
           if ($DevelConf::seperate_ldap==1){
               my $uid_string="";
               if ($uid_number!=-1){
                   $uid_string="-u $uid_number";
               }
               my $sec_string="";
               if ($sec_groups ne ""){
		   $sec_string="-G $sec_groups";
               }

               my $command="";
               if ($type eq "computer"){
                   # computer account $-account
                   my $non_dollar_name=$login;
                   $non_dollar_name=~s/\$//;
                   # command 1
                   $command="smbldap-useradd -w $uid_string -c Computer".
                            " -d /dev/null -g 515 -s /bin/false $login";
      	           print "   * $command\n";
                   system("$command");
           
                   # command 2
                   $command="smbpasswd -a -m $non_dollar_name";
      	           print "   * $command\n";
                   system("$command");           

                   # command 3
                   $command="/usr/sbin/smbldap-usermod -H '[WX]' ".
		            "-S 'Computer' ".
		            "-N 'Computer' $login";
      	           print "   * $command\n";
                   system("$command");           
	       } elsif ($type eq "unixadmin") {
                   # user account, unix only
                   $command="smbldap-useradd $uid_string -c '$gecos'".
                            " -d $home -m -g $g_gidnumber $sec_string".
                            " -s $shell $login";
	           print "   * $command\n";
                   system("$command");           
	       } else {
                   
                   # user account, unix and windows
                   $command="smbldap-useradd -a $uid_string -c '$gecos'".
                            " -d $home -m -g $g_gidnumber $sec_string".
                            " -s $shell $login";
	           print "   * $command\n";
                   system("$command");
                   $command="/usr/sbin/smbldap-usermod -D 'H:'".
                            " -C '${smb_ldap_homepath}'".
                            " -S '${lastname}'".
                            " -N '${gecos}'".
                            " $login";
	           print "   * $command\n";
                   system("$command");           
               }
           }
       } else {
           print "ERROR: Adding user did not suceed in pg as expected!\n";
           print "       Not Adding user to ldap!\n";
       }
   }
}



sub auth_groupadd {
   # $domain_group 0,1
   # $local_group  0,1
   my ($unix_group,$type,
       $gid_number,$nt_group,
       $domain_group,$local_group) = @_;
   # check if adding was succesful
   my ($g_type,$g_name,$g_gidnumber)=&pg_get_group_type($unix_group);
   # add entry to seperate ldap
   if (defined $g_gidnumber){
       if ($g_gidnumber eq $gid_number){
           print "   Succesfully added $unix_group with gidnumber ",
                 "$g_gidnumber to postgres\n";
           # do the ldap stuff
           if ($DevelConf::seperate_ldap==1){
               if ($domain_group==1){
                   print "   Adding domain group $unix_group($nt_group)",
                         " to ldap\n";
               } elsif ($local_group==1){
                   print "   Adding local group $unix_group($nt_group)",
                         " to ldap\n";
               } else {
                   print "ERROR: Dont know which type of group to add.";
                   return 0;
               }
               my ($gr_name,$gr_pass,$gr_gid)=getgrnam($unix_group);
               if (defined $gr_gid){
                  # group exists already
                   if ($gr_gid==$gid_number){
		      print "   Group $unix_group exists already in ldap ",
                            "with correct gid $gr_gid\n";
		  } else {
		      print "WARNING: Group $unix_group",
                            " exists already in ldap ",
                            " with WRONG gid $gr_gid\n";
                  }
               } else {
                  my $group_rid=2*$gid_number+1001;
                  if ($domain_group==1){
                      my $command="";
                      if ($unix_group eq $nt_group){ 
                        # add the domain group
                        $command="smbldap-groupadd -a ".
                                 "-g $gid_number '$unix_group' -t 2";
                        print "   * $command\n";
                        system("$command");
                      } else {
                        # add the domain group
                        $command="smbldap-groupadd ".
                                 "-g $gid_number '$unix_group' -t 2";
                        print "   * $command\n";
                        system("$command");
                        # add correct groupmapping
                        $command="net groupmap add rid=$group_rid".
                            " unixgroup='$unix_group' ntgroup='$nt_group'".
                            " type=domain";
                        print "   * $command\n";
                        system("$command");
		      }
	          }
                  if ($local_group==1){
                      my $command="";
                      if ($unix_group eq $nt_group){ 
                        # add the local group 
                        $command="smbldap-groupadd -a ".
                                 "-g $gid_number '$unix_group' -t 4";
                        print "   * $command\n";
                        system("$command");
		      } else {
                        # add the local group 
                        $command="smbldap-groupadd ".
                                 "-g $gid_number '$unix_group' -t 4";
                        print "   * $command\n";
                        system("$command");
                        # add correct groupmapping
                        $command="net groupmap add sid='S-1-5-32-$group_rid'".
    		               " unixgroup='$unix_group' ntgroup='$nt_group'".
                                 " type=local";
                        print "   * $command\n";
                        system("$command" );
		      }
    	          }
	       }
           } else {
               print "Not using seperate ldap\n";
           }
        } else {
           print "ERROR: Adding group $unix_group did not ",
                 "suceed in pg as expected!\n";
           print "       Not Adding group $unix_group to ldap!\n";
        }
   }
}




sub auth_groupdel {
    my ($group) = @_;

    # find out ntgroupname
    my $nt_groupname=&fetch_nt_groupmap($group);

    my ($g_type,$g_name,$g_gidnumber)=&pg_get_group_type($group);
    if ($g_type eq "nonexisting"){
        # delete groupmapping, if existing
	if ($nt_groupname ne ""){
           $command="net groupmap delete ntgroup='$nt_groupname'";
           print "   * $command\n";
           system("$command");
        }
        # delete group       
        $command="smbldap-groupdel '$group'";
        print "   * $command\n";
        system("$command");
   } else {
        print "Group $group still exists in ldap\n";
        print "   NOT removing group $group from ldap",
   }
}


sub fetch_nt_groupmap {
    my ($unix) = @_;
    my $string=`net groupmap list`;
    my @lines = split(/\n/,$string);
    foreach my $line (@lines){
        my($nt_group,$rest)=split(/\s+\(S/,$line);    
        my ($nothing,$unix_group)=split(/->\s+/,$rest);
        if ($unix eq $unix_group){
            #print "$unix_group maps to $nt_group\n";
            return $nt_group;
        }
    }
    return "";
}








sub auth_usermove {
    # change primary group
    # change home
    my ($login,$gid,$home,$oldgr)=@_;
    # check if movement was successful in postgres
    my ($u_home,$u_type,$u_gecos,$u_group,
       $u_uidnumber)=&fetchdata_from_account($login);

    if ($u_home eq $home and
        $u_group eq $gid){
        print "Moving user in ldap\n";

        # fetch oldgroups
        my $oldgroups=`id -n -G $login`;
        chomp($oldgroups);
        my @oldgroups=split(/ /,$oldgroups);

        # create new list of groups
        my @newgroups=();
        foreach my $gr (@oldgroups){
            if ($gr ne $oldgr){
               push @newgroups,$gr;
	    }
        }
        my $group_csv=join(",",@newgroups);

        my $command="/usr/sbin/smbldap-usermod -g $gid -G".
                    " '$group_csv' -d $home $login";
        print "   * $command\n";
        system("$command");
    } else { 
           print "ERROR: Moving user did not suceed in pg as expected!\n";
           print "       Not moving user in ldap!\n";
    }

}

sub auth_userkill {
    # change home
    my ($login)=@_;
    # check if kill was successful in postgres
    my ($u_home,$u_type,$u_gecos,$u_group,
       $u_uidnumber)=&fetchdata_from_account($login);

    if ($u_home eq "" and $u_type eq ""){
        # killing in pg was succesful
        print "Killing user in ldap\n";
        my $command="smbldap-userdel $login";
        print "   * $command\n";
        system("$command");
    } else { 
           print "ERROR: Killing user did not suceed in pg as expected!\n";
           print "       Not killing user in ldap!\n";
    }

}


sub auth_disable {
    my ($login)=@_;
    my $command="/usr/sbin/smbldap-usermod -I $login";
    print "   * ldap: Disabling samba account ($command)\n";
    system("$command");
}



sub auth_enable {
    my ($login)=@_;
    my $command="/usr/sbin/smbldap-usermod -J $login";
    print "   * ldap: Enabling samba account ($command)\n";
    system("$command");
}

sub auth_deleteuser_from_all_projects {
    # deletes user from all secondary memberships
    my ($login)=@_;
    my $command="/usr/sbin/smbldap-usermod -G '' $login";
    print "   * $command\n";
    system("$command");
}


sub auth_adduser_to_her_projects {
    # add user to all secondary groups
    my ($login,$group_string) = @_;
    my $command="/usr/sbin/smbldap-usermod -G '$group_string' $login";
    print "   * $command\n";
    system("$command");

}


sub auth_adduser_to_project {
    my ($login,$project)=@_;

    # check if adding in pgldap was sucessful ?????

        # fetch oldgroups
        my $oldgroups=`id -n -G $login`;
        chomp($oldgroups);

        my @newgroups=split(/ /,$oldgroups);
        push @newgroups,$project;
        my $group_csv=join(",",@newgroups);

        my $command="/usr/sbin/smbldap-usermod -G '$group_csv' $login";
        print "   * $command\n";
        system("$command");
}




sub auth_deleteuser_from_project {
    my ($login,$project)=@_;

    # check if deletion in pgldap was sucessful ?????

        # fetch oldgroups
        my $oldgroups=`id -n -G $login`;
        chomp($oldgroups);
        my @oldgroups=split(/ /,$oldgroups);

        # create new list of groups
        my @newgroups=();
        foreach my $gr (@oldgroups){
            if ($gr ne $project){
               push @newgroups,$gr;
	    }
        }
        my $group_csv=join(",",@newgroups);

        my $command="/usr/sbin/smbldap-usermod -G '$group_csv' $login";
        print "   * $command\n";
        system("$command");
}



sub auth_firstnameupdate {
   my ($login,$firstname) = @_;
        # firstname is updated only in the db
        #my $command="smbldap-usermod -N '$firstname' $login";
        #print "   * $command\n";
        #system("$command");

}



sub auth_lastnameupdate {
   my ($login,$lastname) = @_;
        my $command="/usr/sbin/smbldap-usermod -S '$lastname' $login";
        print "   * $command\n";
        system("$command");

}



sub auth_gecosupdate {
   my ($login,$gecos) = @_;
   # -c (comment) This is the gecos field
   # -N This is the cn: (common name) 
   my $command="/usr/sbin/smbldap-usermod -c '$gecos' -N '$gecos' $login";
   print "   * $command\n";
   system("$command");
}


sub auth_connect {
    my $ldap = Net::LDAP->new( '127.0.0.1', ) or print "Not connected\n";
    # fetch passwords
    my ($ldappw,$ldap_rootdn,$dbpw)=&fetch_ldap_pg_passwords();
    my $mesg = $ldap->bind( "$ldap_rootdn",
                             password => $ldappw
                           );
    return $ldap;
}



sub auth_disconnect {
    my ($ldap) = @_;
    $ldap->unbind();
}



sub fetch_ldap_pg_passwords {
    my $old_password_file="/etc/ldap/slapd.conf";
    my $ldap_passwd="";
    my $pg_passwd="";
    my $ldap_rootdn="";
    my $ldap_suffix="";
    if (-e $old_password_file) {
         # looking for password
 	 open (CONF, $old_password_file);
         while (<CONF>){
             chomp();
             if (/(^dbpasswd)\s{1,}?(.*)/){
                 # whitespace entfernen
                 my $dbpasswd=$2;
                 $dbpasswd=~s/\s//g;
                 #print "---$dbpasswd---\n";
                 $pg_passwd=$dbpasswd;
	     }
             if (/(^rootpw)\s{1,}?(.*)/){
                 # whitespace entfernen
                 my $rootpw=$2;
                 $rootpw=~s/\s//g;
                 #print "---$rootpw---\n";
                 $ldap_passwd=$rootpw;
	     }
             if (/(^rootdn)\s{1,}?\"(.*)\"/){
                 # whitespace entfernen
                 my $rootdn=$2;
                 $rootdn=~s/\s//g;
                 #print "---$rootdn---\n";
                 $ldap_rootdn=$rootdn;
	     }
             if (/(^suffix)\s{1,}?\"(.*)\"/){
                 # whitespace entfernen
                 my $suffix=$2;
                 $suffix=~s/\s//g;
                 #print "---$suffix---\n";
                 $ldap_suffix=$suffix;
	     }
         }
         close(CONF);
         return ($ldap_passwd,$ldap_rootdn,$pg_passwd,$ldap_suffix);
    } else {
        print "$old_password_file doesn't exist\n";
        return ("","","","");
    }
}


sub dump_slapd_to_ldif {
    my $dump_dir=$DevelConf::log_pfad_slapd_ldif;
    my $dump_file=$dump_dir."/old.ldif";
    if (not -e "$dump_dir"){
        print "Creating $dump_dir\n";
	system("mkdir -p $dump_dir");
    }
  
    print "Dumping slapd to $dump_file\n";
    print "This can take a while ...\n";
    if (not -e ${DevelConf::log_pfad_package_update}){
	system("mkdir -p ${DevelConf::log_pfad_pack_up}");
    }
    system("slapcat -l $dump_file > ${DevelConf::log_pfad_pack_up}/slapcat.log 2>&1"); 
}


sub add_slapd_from_ldif {
    my $dump_dir=$DevelConf::log_pfad_slapd_ldif;
    my $ldif_file=$dump_dir."/old-patched.ldif";
    print "Adding file $ldif_file to ldap\n";
    print "This can take a while ...\n";
    if (-e "$ldif_file"){
        if (not -e ${DevelConf::log_pfad_package_update}){
	    system("mkdir -p ${DevelConf::log_pfad_pack_up}");
        }
        system("slapadd -c -l $ldif_file > ${DevelConf::log_pfad_pack_up}/slapadd-ldif.log 2>&1"); 
    }
}


sub patch_ldif {
    # parameter 1: basedn
    #
    my ($base_dn,$smbworkgroup) = @_;
    my ($dc)=split(/,/,$base_dn);
    $dc=~s/dc=//;
    my $orig="$DevelConf::log_pfad_slapd_ldif"."/old.ldif";
    my $patched="$DevelConf::log_pfad_slapd_ldif/"."old-patched.ldif";
    open(ORIG, "$orig");
    open(PATCHED, ">$patched");
    print "Patching $orig to $patched:\n"; 
    print "   New basedn :   $base_dn\n";
    print "   New dc     :   $dc\n";
    while(<ORIG>){
        chomp();
	if (m/^dn:/){
	    #print "\n$_\n";
            my ($without_dn) = split(/dc=/);
            my $new_dc = $without_dn.$base_dn;
            # [^,]*  are all characters 
            if ($new_dc=~m/(.*sambaDomainName=)[^,]*(,dc=.*)/){
                # print "$1 \n";
                # print "$2 \n";
                my $line=$1.$smbworkgroup.$2;
                $new_dc=$line;
	    }
            print PATCHED "$new_dc\n";
	} elsif (m/^sambaDomainName/){
            print PATCHED "sambaDomainName: $smbworkgroup\n";
	} elsif (m/^dc:/){
            print PATCHED "dc: $dc\n";
        } else {
            print PATCHED "$_\n";
        }
    }
    close(ORIG);
    close(PATCHED);
}



sub compare_pg_with_ldap {
    my ($login) = @_;
    my $count=0;
    my $err_num=0;
    my $ref;
    my $lastref;
    my @error_lines = ();

    # ldap => pg
    my %ldap_pg_mapping= (
        "gecos" => "gecos",
        "cn" => "cn",
        "description" => "description",
        "homeDirectory" => "homedirectory",
        "displayName" => "displayname",
        "sambaHomePath" => "sambahomepath",
        "sambaHomeDrive" => "sambahomedrive",
        "sambaLogonTime" => "sambalogontime",
        "sambaLogoffTime" => "sambalogofftime",
        "sambaKickoffTime" => "sambakickofftime",
        "sambaPwdCanChange" => "sambapwdcanchange",
        "sambaPwdMustChange" => "sambapwdmustchange",
        "sambaAcctFlags" => "sambaacctflags",
        "sambaSID" => "sambasid",
        "sambaPrimaryGroupSID" => "sambaprimarygroupsid"
    );

    # pg
    my $dbh=&Sophomorix::SophomorixPgLdap::db_connect();
    my $sql="SELECT * FROM userdata WHERE uid='$login'";
    my $sth=$dbh->prepare($sql);
    $sth->execute();
    while ( $ref = $sth->fetchrow_hashref ){
	$count++;
	#print $ref->{uid},"\n";
        $lastref=$ref;
    } 
    &Sophomorix::SophomorixPgLdap::db_disconnect($dbh);
    my %pg_hash=%$lastref;

    # remove spaces at the end of description in pg
    my $tmp = $pg_hash{'description'};
    $tmp=~s/\s*$//;
    $pg_hash{'description'}=$tmp;

    # ldap
    my $ldap=&Sophomorix::SophomorixPgLdap::auth_connect();
    my ($ldappw,$ldap_rootdn,$dbpw,$suffix)=&fetch_ldap_pg_passwords();
    # search in ou=accounts and ou=machines (i.e. suffix alone)
    my $msg = $ldap->search(
          base => "$suffix",
          scope => "sub",
          filter => "(uid=$login)"
       );
    if($Conf::log_level>=3){
        print "  Ldap has returned ",$msg->count(), 
              " entry/entries for $login\n";
    }

    my $entry = $msg->entry(0);
    while(my ($ldap_attr, $pg_col) = each(%ldap_pg_mapping)) {
        if (defined $entry->get_value( $ldap_attr ) ){
            if($Conf::log_level>=3){
                printf "    ldap: %-21s%-54s\n","$ldap_attr:",
                       $entry->get_value( $ldap_attr );
            }
        } else {
            push @error_lines,"   ERROR: $ldap_attr: NOT DEFINED";
            if($Conf::log_level>=3){
                printf "    ldap: %-21s%-54s\n","$ldap_attr:",
                       "ERROR: NOT DEFINED!";
	    }
        }
        if (defined $pg_hash{$pg_col}){
            if($Conf::log_level>=3){
                printf "    pg:   %-21s%-54s\n","$pg_col:",$pg_hash{$pg_col};
            }
        } else {
            push @error_lines,"   ERROR: $pg_col: NOT DEFINED";
            if($Conf::log_level>=3){
                printf "    pg:   %-21s%-54s\n","$pg_col:",
                       "ERROR: NOT DEFINED!";
            }
        }     
        if (defined $entry->get_value( $ldap_attr ) 
            and defined $pg_hash{$pg_col}){
            # compare
            if ($entry->get_value( $ldap_attr ) eq $pg_hash{$pg_col}){
                #print "OK:   $ldap_attr <-> $pg_col\n";
            } else {
                push @error_lines,"   ERROR: $ldap_attr and $pg_col differ";
                #print "ERROR:$ldap_attr and $pg_col differ\n";
            }
        } else {
            if (not defined $entry->get_value( $ldap_attr ) ){
                if($Conf::log_level>=3){
                   print "    ERROR:$ldap_attr and $pg_col (ldap undef)\n";
	        }
            } elsif (not defined $pg_hash{$pg_col} ){
                if($Conf::log_level>=3){
                   print "    ERROR:$ldap_attr and $pg_col (pg undef)\n";
	        }
            }
        }
    }
  
    @error_lines = sort @error_lines;
    foreach my $line (@error_lines){
       print $line,"\n";
    }
#    foreach my $attrib ( $entry->attributes() ){
#        foreach my $val ( $entry->get_value( $attrib ) ){
#            print "Comparing $attrib (ldap) with \n";
#        }
#    }
    &Sophomorix::SophomorixPgLdap::auth_disconnect($ldap);
    return $#error_lines+1;
}


# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
