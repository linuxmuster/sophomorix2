#!/usr/bin/perl -w
# $Id$
# This perl module is maintained by Rüdiger Beck
# It is Free Software (License GPLv3)
# If you find errors, contact the author
# jeffbeck@web.de  or  jeffbeck@gmx.de


package Sophomorix::SophomorixConfig;
require Exporter;
use Time::Local;
use Time::localtime;


@ISA = qw(Exporter);

@EXPORT_OK = qw( );
@EXPORT = qw( 
              );


my $conf="/etc/sophomorix/user/sophomorix.conf";
if (not -e $conf){
    print "ERROR: $conf not found!\n";
    exit;
}

# Einlesen der Konfigurationsdatei
{ package Conf ; do "$conf"}
# Die in sophomorix.conf als global (ohne my) deklarierten Variablen
# können nun mit $Conf::Variablenname angesprochen werden


=head1 Documentation of SophomorixConfig.pm

For documentation see module SophomorixAPI (perldoc Sophomorix:.SophomorixAPI).

=cut


my $develconf="/usr/share/sophomorix/devel/sophomorix-devel.conf";
if (not -e $develconf){
    print "ERROR: $develconf not found!\n";
    exit;
}

# Einlesen der Konfigurationsdatei für Entwickler
{ package DevelConf ; do "$develconf"}









sub show_language {
#    if($Conf::log_level>=2){
       &titel("Language:   $Conf::lang");
#   }
}









# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
