#!/usr/bin/perl -w
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
             pg_get_adminclasses
             fetchadminclasses_from_school
             fetchsubclasses_from_school
             fetchprojects_from_school
             fetchrooms_from_school
             fetchworkstations_from_school
             fetchworkstations_from_room
             set_sophomorix_passwd
             user_deaktivieren
             user_reaktivieren
	     update_user_db_entry
	     remove_user_db_entry
             create_project
             remove_project
             get_sys_users
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
             show_room_list
             get_smb_sid
);
# deprecated:             move_user_db_entry
#                         move_user_from_to
#                         show_class_list


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


# ===========================================================================
# Loading the sys-db-Module, list of functions
# ===========================================================================
# list of functions to load if sys_db is 'files'
use if ${DevelConf::sys_db} eq 'files' , 
    'Sophomorix::SophomorixSYSFiles' => qw( add_class_to_sys
                                            get_user_auth_data
                                          );

use if ${DevelConf::sys_db} eq 'pgldap' , 
    'Sophomorix::SophomorixSYSPgLdap' => qw( add_class_to_sys
                                            get_user_auth_data
                                          );


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
    my $dbname="ldap";
    my $dbuser="postgres";
    # password not needed because of postgres configuration
    # in pg_hba.conf pg_ident.conf
    my $pass_saved="";
    if($Conf::log_level>=3){
       print "Connecting to database ...\n";
    }
    # needs at UNIX sockets:   local all all  trust sameuser
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$dbuser","$pass_saved",
               { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    if (defined $dbh){
       if($Conf::log_level>=3){
          print "   Connection with password $pass_saved successful!\n";
          print "   Database $dbname ready for user $dbuser!\n";
       }
    } else {
       print "   Could not connect to database with password $pass_saved!\n";
    }
    return $dbh
}


# connect to sql database
sub db_disconnect {
    my ($dbh) = @_;
    $dbh->disconnect();
    if($Conf::log_level>=3){
       print "Disconnecting ...\n";
    }
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
              { RaiseError => 1, PrintError => 1});

    # ldap
    if($Conf::log_level>=3){
       print "   Checking ldap connection... \n";
    }
    my $ldap = Net::LDAP->new( '127.0.0.1' ) or die "$@";
}




##############################################################################
#                                                                            #
#  Functions for projects                                                    #
#                                                                            #
##############################################################################

sub fetchinfo_from_project {
    my ($project) = @_;
    my $dbh=&db_connect();
    my ($longname,$addquota,$add_mail_quota,$status,$join,
        $time,$max_members,$mailalias,
        $maillist) = $dbh->selectrow_array( "SELECT longname,addquota,
           addmailquota,sophomorixstatus,joinable,creationdate,maxmembers,
           mailalias,maillist
                          FROM projectdata 
                          WHERE gid='$project'");
    # Merging information:
    &db_disconnect($dbh);
    return ($longname,$addquota,$add_mail_quota,
            $status,$join,$time,$max_members,$mailalias,$maillist);    
}



sub fetchusers_from_project {
    # return a list of uid of users of the given project
    # linux: which users are secondary members of group
    my ($group) = @_;
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




sub fetchadmins_from_project {
    # return a list of uid of admins of the given project
    my ($group) = @_;
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
    my ($user,$project)=@_;
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

}


sub deletegroup_from_project {
    # remove group from project
    my ($group,$project)=@_;
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
    print "   Removing user $user($uidnumber_sys) from all projects \n";
    my $sql="DELETE FROM groups_users 
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
}







sub adduser_to_project {
    # add a user as secondary membership to a project(group)
    my ($user,$project)=@_;
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
    my ($home,$group)= $dbh->selectrow_array( "SELECT homedirectory,gid 
                                         FROM userdata 
                                         WHERE uid='$login'
                                        ");
    if ($group  eq ${DevelConf::teacher}){
	$type="teacher";
    } elsif ($group eq "administrators"){
        $type="administrator";
    } elsif ($home=~/\/workstation\//){
        $type="workstation";
    } else {
        $type="student";
    }
    &db_disconnect($dbh);
    if (defined $home){
        return ($home,$type);
    } else {
	return ("","");
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
       $gecos_force) = @_;

    if (not defined $mailquota){
       $mailquota=-1;
    }

    if (not defined $pg_timestamp){
       $pg_timestamp=$today_pg;
    }
    if (not defined $sophomorix_status){
       $sophomorix_status="U";
    }
    if (not defined $gecos_force or $gecos_force eq ""){
       $gecos = "$vorname"." "."$nachname";
    } else {
       $gecos = $gecos_force;
    }
    my $homedir="";
    if ($admin_class eq ${DevelConf::teacher}){
        # teachers
        $homedir = "${DevelConf::homedir_teacher}/$login";
    } else {
        # students
        $homedir = "${DevelConf::homedir_pupil}/$admin_class/$login";
    }

    if (defined $homedir_force){
        $homedir=$homedir_force;
    }

    my $description="perl: create_user_db_entry";
    my $birthday_pg = &date_perl2pg($birthday_perl);

    # create crypt password for liux
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
    if (defined $id_force and $id_force ne ""){ 
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
        print "user $login already exists ($uidnumber)\n";
    } elsif ($uid_name_sys ne ""){
        # uid found
        my $uidname=$uid_name_sys;
        print "uidnumber $id_force exists already ($uidname)\n";
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
       $sql="select manual_get_next_free_uid()";
       if($Conf::log_level>=3){
          print "SQL: $sql\n";
       }
       my $uidnumber = $dbh->selectrow_array($sql);
       if (defined $id_force and $id_force ne ""){
           # force the id if given as parameter
	   $uidnumber=$id_force;
       }
       if($Conf::log_level>=3){
          print "   --> \$uidnumber ist $uidnumber \n\n";
       }

       # neue gruppe anlegen und gidnumber holen, falls erforderlich
       my $gidnumber=&create_class_db_entry($admin_class);

       # get_sid
       my $sid = &get_smb_sid();
       # smb user sid
       my $user_sid = &smb_user_sid($uidnumber,$sid);
       print "USER-SID:        $user_sid\n";
       # smb group sid
       my $group_sid = &smb_group_sid($gidnumber,$sid);
       print "GROUP-SID:       $group_sid\n";

       my $smb_homepath="\\\\\\\\server\\\\$login";

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
         NULL,
         '$lmpassword',
         '$ntpassword',
         '$unix_epoc',
         '0',
         '2147483647',
         '2147483647',
         '0',
         '2147483647',
         '[UX]',
         '$gecos',
         '$smb_homepath',
         'H:',
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
      $dbh->disconnect();
  } else {
      if($Conf::log_level>=3){
         print "Test:   Wrote entry into database\n";
      }
  }
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
    my ($class_to_add,$sub,$gid_force_number) = @_;
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
        $type="manualgroup";
    } else {
        $type="subclass";
    }
    if (not defined $gid_force_number){
        $gid_force_number=-1;
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
           #Freie GID holen
           $sql="select manual_get_next_free_gid()";
           if($Conf::log_level>=3){
              print "\nSQL: $sql\n";
           }
           $gidnumber = $dbh->selectrow_array($sql);
           print "Received $gidnumber as next free gidnumber\n";
       }

    # Gruppe anlegen, Funktion
    $sql="SELECT manual_create_ldap_for_group('$class_to_add')";
    if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
    }
    my $groups_id = $dbh->selectrow_array($sql);

    #Gruppe anlegen (2Tabellen)
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
    my $group_sid = &smb_group_sid($gidnumber,$sid);

    #2. Tabelle samba_group_mapping
    #Pflichtfelder (laut Datenbank) id
    # sambagrouptype (2=domaingroup(defaultgroup), 4=localgroup, 5=builtingroup)
    $sql="INSERT INTO samba_group_mapping
	 (id,gidnumber,sambasid,sambagrouptype,displayname,description,sambasidlist)
	 VALUES
	 ($groups_id,
          $gidnumber,
          '$group_sid',
          '2',
          '$class_to_add',
          NULL,
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
#        if($Conf::log_level>=3){
#           print "\nSQL: $sql\n";
#        }
#        $dbh->do($sql);

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







# adds a class to the user database
sub remove_class_db_entry {
    my ($group) = @_;
    my $dbh=&db_connect();

    # Gruppe loeschen, Funktion
    my $sql="SELECT manual_delete_groups('$group')";
    if($Conf::log_level>=3){
        print "\nSQL: $sql\n";
    }
    my $return = $dbh->selectrow_array($sql);
    if (defined $return){
        print "Group $return ($group) removed!\n";
    } else {
        print "\nERROR: Could not delete group $group \n\n";
    }
    &db_disconnect($dbh);
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
            print "   User $user(${uidnumber})exists ",
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
        push @grp_list, $sec_gid;
        $i++;
    }   

    return @grp_list;
}


sub pg_get_group_type {
    my ($gid) = @_;
    my $return="";
    my $dbh=&db_connect();
    # fetching project_id
    my ($id_sys,$gidnumber_sys)= $dbh->selectrow_array( "SELECT id,gidnumber 
                                         FROM groups 
                                         WHERE gid='$gid'");
    if (not defined $id_sys){
        # if not in pgldap
	return ("unknown",$gid);
    }    
    my ($type)= $dbh->selectrow_array( "SELECT type 
                                          FROM classdata 
                                          WHERE id='$id_sys'");
    if (not defined $type){
        # not adminclass, not subclass
        
        my ($longname)= $dbh->selectrow_array( "SELECT longname
                                          FROM projectdata 
                                          WHERE id='$id_sys'");
        if (defined $longname){
            return ("project",$longname);
        } else {
           # look at a users home

           my ($home)= $dbh->selectrow_array( "SELECT homedirectory 
                                          FROM userdata 
                                          WHERE gidnumber=$gidnumber_sys");
           if ($home=~/^\/home\/workstations\//){
               # identify a workstation 
	       return ("room",$gid);
           } elsif ($home=~/^\/home\/administrators\//){
               # identify an administrator
               return ("administrator",$gid);
           } else {
               return ("unknown",$gid);
           }
        }
    } elsif ($type eq "subclass"){
        # subclass
        return ("subclass",$gid);
    } elsif ($type eq "adminclass"){
        # adminclass
        return ("adminclass",$gid);
    }


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
                              ORDER BY gid" );
      $sth->execute();
    my $array_ref = $sth->fetchall_arrayref();
    my $i=0;
    foreach ( @{ $array_ref } ) {
        my $gid=${$array_ref}[$i][0];
        push @admin_classes, $gid;
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
        push @sub_classes, $gid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @sub_classes;
}


sub fetchprojects_from_school {
    # fetch all subclasses
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
    # fetch all subclasses
    my @rooms=();
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT DISTINCT gid
                             FROM userdata 
                             WHERE homedirectory LIKE '/home/workstations/%'
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
    my @rooms=();
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
        my $gid=${$array_ref}[$i][0];
        push @rooms, $gid;
        $i++;
    }   
    &db_disconnect($dbh);
    return @rooms;
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

   my $dbh=&db_connect();

# select the columns that i need
my $sth= $dbh->prepare( "SELECT uid, firstname, surname, birthday, adminclass, exitadminclass, unid, subclass, tolerationdate, deactivationdate, sophomorixstatus FROM userdata" );
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
      print "  Login       :   $login \n"; 
      print "  AdminClass  :   $admin_class \n";
      print "  Birthday(pg):   $birthday_pg \n";
      print "  Birthday(pl):   $birthday \n";
      print "  Identifier  :   $identifier \n";

      print "User Attributes (MAY): \n";

      # unid is optional
      if ($unid ne "") {
         print "  Unid              :   $unid \n" ;
      } else {
         print "  Unid              :   --- \n" ;
      }

      # subclass is optional
      if ($subclass ne "") {
         print "  SubClass          :   $subclass \n" ;
      } else {
         print "  SubClass          :   --- \n" ;
      }

      # Status
      if ($status ne "") {
         print "  Status            :   $status \n" ;
      } else {
         print "  Status            :   --- \n" ;
      }

      # TolerationDate is optional
      if ($toleration_date ne "") {
         print "  TolerationDate    :   $toleration_date \n" ;
      } else {
         print "  TolerationDate    :   --- \n" ;
      }

      # DeactivationDate is optional
      if ($deactivation_date ne "") {
         print "  DeactivationDate  :   $deactivation_date \n" ;
      } else {
         print "  DeactivationDate  :   --- \n" ;
      }

      # ExitAdminClass is optional
      if ($exit_admin_class ne "") {
         print "  ExitAdminClass    :   $exit_admin_class \n" ;
      } else {
         print "  ExitAdminClass    :   --- \n" ;
      }

      # AccountType is optional
      if ($account_type ne "") {
         print "  AccountType       :   $account_type \n" ;
      } else {
         print "  AccountType       :   --- \n" ;
      }

          print "\n";
   }# end loglevel

   # In Hash schreiben: mit Klasse als Wert (um Versetzen herauszufinden)
#   $schueler_im_system_hash{$identifier}="$admin_class";
   # In Hash schreiben: mit loginnamen als Wert (um Löschen herauszufinden)
#   $schueler_im_system_loginname{$identifier}="$login";
   # In Hash schreiben: mit Zeile als Wert (beim Löschen zu entfernen)
#   $schueler_im_system_protokoll_linie{$identifier}="$_";

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

   # ExitAdminClass is optional
   if ($exit_admin_class ne "") {        
      $identifier_exit_adminclass{$identifier} = "$exit_admin_class";
   }

   # AccountType is optional
   if ($account_type ne "") {        
      $identifier_account_type{$identifier} = "$account_type";
   }


   # increase counter for users
   $number++;

}

    $dbh->disconnect();

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
          \%identifier_account_type
         );
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

    # select the columns that i need
    my $sth= $dbh->prepare( "SELECT uid, firstname, 
                                    surname, birthday, 
                                    adminclass, firstpassword,
                                    sophomorixstatus 
                             FROM userdata" );
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
    my $exit_admin_class="";
    my $account_type="";
    my $quota="";
    my $mailquota=-1;

    my @posix=();
    my @posix_details=();
    my @samba=();
  
    my $dbh=&db_connect();
    my $sql="";
    
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
           $firstname="$value";
	   push @posix, "firstname = '$firstname'";
       }
       elsif ($attr eq "LastName"){
           $lastname="$value";
	   push @posix, "surname = '$lastname'";
       }
       elsif ($attr eq "Gecos"){
           $gecos="$value";
	   push @posix, "gecos = '$gecos'";
	   push @samba, "displayname = '$gecos'";
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
       elsif ($attr eq "ExitAdminClass"){
           $exit_admin_class="$value";
           push @posix_details, "exitadminclass = '$exit_admin_class'";
           }
       elsif ($attr eq "Gid"){
           $gid_name="$value";
           print " ****adding $gid_name\n";
           # neue gruppe anlegen und gidnumber holen, falls erforderlich
           $gid_number=&create_class_db_entry($gid_name);
           # homedirectory
           if ($gid_name eq ${DevelConf::teacher}) {
              # in klasse lehrer versetzten
              $home_dir="${DevelConf::homedir_teacher}/${login}";
           } else {
              # in andere Klasse versetzten (auch dachboden/speicher)
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
    if($Conf::log_level>=3){
       print "Retrieved Id of $login: $id \n";
    }


    if (defined $id){
       # if user found in database
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
    print "Deleted User $login ($uidnumber)\n";

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

   # samba
   my $samba_string="smbpasswd -d $login >/dev/null";
   if($Conf::log_level>=2){
      print "   Disabling samba login of $login:  $samba_string\n";
   }
   system("$samba_string");

   # linux
   # fetch the old crypted password
   my $dbh=&db_connect();
   my $sql="";
   $sql="SELECT userpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($crypt_pass)= $dbh->selectrow_array($sql);
   print "   Unix password: $crypt_pass\n";

   if (not defined $crypt_pass){
       print "   User $login not found in database to disable unix-account!\n";
   } elsif ($crypt_pass=~m/!$/) {
       print "   Unix account of $login is already disabled!\n";
   } else {
       print "   Disabling unix account of $login!\n";
       # append ! to pasword
       $crypt_pass="$crypt_pass"."!";
       # replace password
       print "Replacing password with --$crypt_pass-- \n";
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
#   my $linux_string="usermod -L $login >/dev/null";
#   system("$linux_string");
   if($Conf::log_level>=2){
      print "Samba:  $samba_string\n";
    }
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

   # samba
   my $samba_string="smbpasswd -e $login >/dev/null";
   if($Conf::log_level>=2){
      print "   Enabling samba login of $login:  $samba_string\n";
   }
   system("$samba_string");

   # linux
   # fetch the old crypted password
   my $dbh=&db_connect();
   my $sql="";
   $sql="SELECT userpassword FROM userdata WHERE uid='$login'";
   if($Conf::log_level>=3){
      print "\nSQL: $sql\n";
   }
   my ($crypt_pass)= $dbh->selectrow_array($sql);
   if($Conf::log_level>=3){
      print "   Unix password: $crypt_pass\n";
   }

   if (not defined $crypt_pass){
       print "   User $login not found in database to enable unix-account!\n";
   } elsif (not $crypt_pass=~m/!/) {
       print "   Unix account of $login is already enabled!\n";
   } else {
       print "   Enabling unix account of $login!\n";
       # remove ! from pasword
       $crypt_pass=~s/!$//g;
       # replace password
       print "Replacing password with --$crypt_pass-- \n";
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
        $p_mailalias,$p_maillist) = @_;
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

    # MaxMambers
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
    my %admins_to_add=();
    my %projects_to_add=();

    my @users_to_add=();
    my @admins_to_add=();
    my @groups_to_add=();
    my @projects_to_add=();

    my $old_users="";
    my @old_users=();
    my @old_admins=();
    my @old_groups=();
    my @old_projects=();

    my %seen=();

    my @new_members=();
    my @new_admins=();
    my @new_groups=();
    my @new_projects=();

    &Sophomorix::SophomorixBase::provide_project_files($project);

    # get old values
    @old_users=&fetchusers_from_project($project);
    @old_admins=&fetchadmins_from_project($project);
    @old_groups=&fetchgroups_from_project($project);
    @old_projects=&fetchprojects_from_project($project);

    # Adding all users/admins/projects from options to lists
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
#        @new_users_pri=&Sophomorix::SophomorixBase::get_user_adminclass($group);
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
        # select the secondary users
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
        }
    }

    foreach my $memb (@new_members){
	$users_to_add{ $memb }="member";
    }

    foreach my $memb (@new_admins){
	$users_to_add{ $memb }="admin";
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
	 &deleteuser_from_project($user,$project);
         &Sophomorix::SophomorixBase::remove_share_link($user,
                                         $project,$p_long_name);
       } 
    }    
    
    while (my ($user) = each %users_to_add){
       #print "$user must be added\n";
       push @users_to_add, $user;
    }
    # sorting
    @users_to_add = sort @users_to_add;
    print "     Users to add: @users_to_add\n";
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
    print "     Users to add as admins: @admins_to_add\n";
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
         #system("gpasswd -d $user $project");
	 &deletegroup_from_project($group,$project);
         # do this for all users ????????
         #&Sophomorix::SophomorixBase::remove_share_link($user,$project);
       } 
    }    
    
    while (my ($group) = each %groups_to_add){
       print "$group must be added\n";
       push @groups_to_add, $group;
    }
    # sorting
    @groups_to_add = sort @groups_to_add;
    print "     Groups to add: @groups_to_add\n";
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
	 &deleteproject_from_project($m_project,$project);
       } 
    }    
    
    while (my ($m_project) = each %projects_to_add){
       push @projects_to_add, $m_project;
    }
    # sorting
    @projects_to_add = sort @projects_to_add;
    print "     Projects to add as members: @projects_to_add\n";
    # adding the projects
    foreach my $m_project (@projects_to_add) {
	if ($m_project ne $project){
            &addproject_to_project($m_project,$project);
        } else {
            print "WARNING: Not adding $project to itself!\n";
        }
    }
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
  my ($string) = @_;
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
  my $sth= $dbh->prepare( "SELECT DISTINCT uid, firstname, surname, loginshell, 
                            birthday, adminclass, exitadminclass, 
                            unid, subclass, creationdate,tolerationdate, 
                            deactivationdate, sophomorixstatus,
                            gecos, homedirectory, firstpassword, quota,
                            sambaacctflags, sambahomepath, sambahomedrive,
                            sambalogonscript,sambaprofilepath 
                         FROM userdata
                         WHERE uid LIKE $str
                            OR firstname LIKE $str
                            OR surname LIKE $str
                            OR gecos LIKE $str
                            OR displayname LIKE $str" );
  $sth->execute();

  my $array_ref = $sth->fetchall_arrayref();

  foreach my $row (@$array_ref){
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
           $sambaacctflags, 
           $sambahomepath,
           $sambahomedrive,
           $sambalogonscript,
           $sambaprofilepath, 
           ) = @$row;

       my $birthday=&date_pg2perl($birthday_pg);
       my $tol=&date_pg2perl($toleration_date_pg);
       my $deact=&date_pg2perl($deactivation_date_pg);

       # Gruppen-Zugehoerigkeit
       $pri_group_string="";
       $grp_string="";
       @group_list=&Sophomorix::SophomorixPgLdap::pg_get_group_list($login);
       $pri_group_string=$group_list[0];

       # standard Values for nonsophomorix users
       if (not defined $admin_class){$admin_class=""}
       if (not defined $first_pass){$first_pass=""}
       if (not defined $cre){$cre=""}


       if (defined $login){
	     print "($login exists in the system) \n";
       } else {
	     print "(ERROR: $login is not in the system) \n";
       }
       print "=======================================";
       print "=======================================\n";

       printf "  AdminClass       : %-47s %-11s\n",$admin_class,$login;
       printf "  PrimaryGroup     : %-47s %-11s\n",$pri_group_string,$login;

       foreach my $gr (@group_list){
	   $grp_string= $grp_string." ".$gr;
       }
       printf "  SecondaryGroups  :%-48s %-11s\n",$grp_string,$login;
       printf "  Gecos            : %-47s %-11s\n", $gecos,$login;

       if (-e $home){
          $home_ex=$home."  (existing)";
       } else {
          $home_ex=$home."  (ERROR: non-existing)";
       }
       if (defined $home){
          printf "  Home             : %-47s %-11s\n",$home_ex,$login;
       }

       if (defined $loginshell){
          printf "  loginShell       : %-47s %-11s\n",$loginshell,$login;
       }

       print "Sophomorix:\n";

       printf "  FirstPassword    : %-47s %-11s\n",$first_pass,$login;
       printf "  Birthday         : %-47s %-11s\n",$birthday,$login;

       if (defined $unid){
          printf "  Unid             : %-47s %-11s\n",$unid,$login;
       }

       if (defined $subclass){
	  printf "  SubClass         : %-47s %-11s\n",$subclass,$login;
       }

       if (defined $status){
	  printf "  Status           : %-47s %-11s\n",$status,$login;
       }

       if (defined $tol){
          printf "  CreationDate     : %-47s %-11s\n",$cre,$login;
       }

       if (defined $tol){
          printf "  TolerationDate   : %-47s %-11s\n",$tol,$login;
       }

       if (defined $deact){
          printf "  DeactivationDate : %-47s %-11s\n",$deact,$login;
       }

       if (defined $ex_admin){
	  printf "  ExitAdminClass   : %-47s %-11s\n",$ex_admin,$login;
       }

       if (defined $acc_type){
	  printf "  AccountType      : %-47s %-11s\n",$acc_type,$login;
       }

       if($Conf::use_quota eq "yes"){
          if (defined $quota){
	     printf "  Quota (MB)       : %-47s %-11s\n",$quota,$login;
          } else {
	     print  "  Quota (MB)       : --- \n";
          }
          if (-e "/usr/bin/quota"){
#	     print "  "; # indent output of following command
             # -l show only local quota, no nfs
             # -v show quota on unused filesystems          
             #system("quota -l -v $login");
             my $show=`quota -l -v $login`;
	     print "  "; # indent output of following command
             $show =~ s/\n  /\n/g; # remove indent partially
             print $show;
          }
       }

       print "Samba:\n";

       if (defined $sambaacctflags){
          printf "  sambaAcctFlags   : %-47s %-11s\n",$sambaacctflags,$login;
       }

       if (defined $sambahomepath){
          printf "  sambaHomePath    : %-47s %-11s\n",$sambahomepath,$login;
       }

       if (defined $sambahomedrive){
          printf "  sambaHomeDrive   : %-47s %-11s\n",$sambahomedrive,$login;
       }

       if (defined $sambalogonscript){
          printf "  sambaLogonScript : %-47s %-11s\n",$sambalogonscript,$login;
       }

       if (defined $sambaprofilepath){
          printf "  sambaProfilePath : %-47s %-11s\n",$sambaprofilepath,$login;
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
#    my ($time, $string) = @_;
#    &do_falls_nicht_testen(
#      "cp ${DevelConf::protokoll_pfad}/user_db ${DevelConf::log_pfad}/${time}.user_db-${string}",
#      "chmod 600 ${DevelConf::log_pfad}/${time}.user_db-${string}"
#    );
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
    print "The following projects exist already:\n\n";
    printf "%-16s|%9s |%4s |%3s |%1s|%1s|%1s|%1s| %-22s \n",
           "Project","AddQuota","AMQ","MM","A","L","S","J","LongName";
    print "----------------+----------+-----+----+-+-",
          "+-+-+---------------------------------\n";
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
        printf "%-16s|%9s |%4s |%3s |%1s|%1s|%1s|%1s| %-22s\n",$gid,
                $addquota,$addmailquota,$maxmembers,$mailalias,
                $maillist,$status,$joinable,$longname;
        $i++;
    }   
    print "----------------+----------+-----+----+-+-",
          "+-+-+---------------------------------\n";
    print "(AMQ=AddMailQuota, MM=MaxMembers, A=Mailalias,",
          " L=Mailist, S=Status, J=Joinable)\n";
    &db_disconnect($dbh);
}






sub show_class_list {
    print "The following adminclasses exist already:\n\n";
    printf "%-14s | %8s |%4s |%1s|%1s| %-19s| %-20s\n","AdminClass",
           "Quota", "MQ","A","L","SchoolType","Department";
    print "---------------+----------+-----",
          "+-+-+--------------------+---------------------\n";
    my $dbh=&db_connect();
    my $sth= $dbh->prepare( "SELECT gid,quota,mailquota,mailalias,
                                    maillist,schooltype,department
                             FROM classdata
                             WHERE type='adminclass'
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
        printf "%-15s|%10s|%4s |%1s|%1s| %-19s| %-18s\n",$gid,
                $quota,$mailquota,$mailalias,$maillist,
                $schooltype,$department;
        $i++;
    }   
    print "---------------+----------+-----",
          "+-+-+--------------------+---------------------\n";
    print "(MQ=MailQuota, A=Mailalias,",
          " L=Mailist)\n";
    &db_disconnect($dbh);
}




sub show_class_teacher_list {
    print "To do: classes --> teachers \n";
}




sub show_teacher_class_list {
    print "To do: teachers --> classes \n";
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
    #my $dbh=&db_connect();
    my ($longname,$addquota,$add_mail_quota,
        $status,$join,$time,$max_members,
        $mailalias,$maillist)=&fetchinfo_from_project($project);
    if (defined $longname){
       print "Project:          $project\n";
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
    my @user=&fetchusers_from_project($project);
    @user = sort @user;
    &Sophomorix::SophomorixBase::print_list_column(4,"Members of $project",@user);
    print "\n";
    my @admins=&fetchadmins_from_project($project);
    @admins = sort @admins;
    &Sophomorix::SophomorixBase::print_list_column(4,"Admins of $project",@admins);
    print "\n";
    my @groups=&fetchgroups_from_project($project);
    @groups = sort @groups;
    &Sophomorix::SophomorixBase::print_list_column(4,"Groups of $project",@groups);
    print "\n";
    my @pro=&fetchprojects_from_project($project);
    @pro = sort @pro;
    &Sophomorix::SophomorixBase::print_list_column(4,
      "MemberProjects of $project",@pro);
    #&db_disconnect($dbh);
}



sub show_room_list {
    my @rooms = &fetchrooms_from_school();
    my $number=0;
    my $sum=0;
    my $dbh=&db_connect();
    print "The following rooms exist already:\n\n";
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
    my $group_sid=2*$gidnumber+1001;
    $group_sid="$sid"."-"."$group_sid";
    return $group_sid;
}


sub get_smb_sid {
    $sid_string=`net getlocalsid`;
    chomp($sid_string);
    my ($rubbish,$sid) = split(/: /,$sid_string);
    return $sid;
}




# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
