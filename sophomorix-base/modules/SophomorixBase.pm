#!/usr/bin/perl -w
# Dieses Modul (SophomorixBase.pm) wurde von Rüdiger Beck erstellt
# Es ist freie Software
# Bei Fehlern wenden Sie sich bitte an mich.
# jeffbeck@web.de  oder  jeffbeck@gmx.de

package Sophomorix::SophomorixBase;
require Exporter;
use Time::Local;
use Time::localtime;


@ISA = qw(Exporter);

@EXPORT_OK = qw( check_datei_touch );
@EXPORT = qw( linie 
              titel 
              formatiere_liste
              get_alle_verzeichnis_rechte
              get_v_rechte
              setup_verzeichnis
              user_login_hash
              save_tausch_klasse
              neue_linux_gruppe_schueler
              user_links
              protokoll_linien
              extra_kurs_schueler
              lehrer_ordnen
              zeit_stempel
              do_falls_nicht_testen
              help_text_all
              check_options
              check_datei_exit
              check_config_template
              check_datei_touch
              check_verzeichnis_mkdir
              print_user_samba_data
              get_user_history
              get_group_list
              print_forward
              create_share_link
              remove_share_link
              zeit
              get_klasse_von_login
              get_schueler_in_klasse
              get_schueler_in_schule
              get_schueler_in_schule_hash
              get_lehrer_in_schule
              get_lehrer_in_schule_hash
              get_workstations_in_schule
              get_workstations_in_schule_hash
              get_workstations_in_raum
              get_klassen_in_schule              
              get_klassen_in_schule_hash
              check_klasse
              get_raeume_in_schule              
              get_ka_raeume_in_schule              
              get_raeume_in_schule_hash              
              check_raum
              check_lehrer
              make_hash_lehrer_in_klassen
              get_lehrer_in_klasse
              get_raum_buchung
              get_config_datei_meine_klassen
              get_link_pfad
              datum_loeschen_schueler
              daten_loeschen_ich_lehrer
              daten_loeschen_lehrer
              daten_loeschen
              get_dir_list
              td_ausgeben
              liste_ausgeben
              get_mail_alias_from
              check_quotastring
              setze_quota
              get_standard_quota
              get_lehrer_quota
              get_klassen_quota
              get_quota_fs_liste
              sophomorix_passwd
              get_erst_passwd
              check_internet_status
              austeilen_manager
              ka_austeilen
              unterricht_austeilen
              ka_einsammeln
              unterricht_einsammeln
              provide_class_files
              );




use Sophomorix::SophomorixSYSFiles qw ( 
                                    get_user_auth_data
                                  );





=head1 Documentation of SophomorixBase.pm


B<sophomorix> is a user administration tool for a school server. It
lets you administrate a huge amount of users by exporting all pupils of
a school into a file and reading them into a linux system.

B<Sophomorix> will in the future use different backends (files, ldap,
SQL-Databases, ...) to store its data. If you want to access this data
you could talk to the backend directly, but this would mean, that you
would have to update your scripts when the data organisation in the
backend changes.

A better way is to use only the functions of B<SophomorixBase>. So if
the data organisation changes you only have to get a current version
of B<SophomorixBase> and youre off.


=head2 FUNCTIONS

=head3 Formatting

=over 4

=cut

# Einlesen der Konfigurationsdatei für Entwickler
{ package DevelConf ; do "/etc/sophomorix/devel/user/sophomorix-devel.conf"}

# Einlesen der Konfigurationsdatei
{ package Conf ; do "${DevelConf::config_pfad}/sophomorix.conf"}
# Die in sophomorix.conf als global (ohne my) deklarierten Variablen
# können nun mit $Conf::Variablenname angesprochen werden


################################################################################
# FORMATIERUNGEN
################################################################################
=pod

=item I<linie()>

Creates a line.

=cut
sub linie {
   print "========================================",
         "========================================\n";
}


=pod

=item I<titel(text)>

Creates a framed titel with the text I<text>. The frame is thinner,
when --verbose is not used.

=cut
sub titel {
   my ($a) = @_;

   if($Conf::log_level>=2){
   print  "\n#########################################", 
                            "#######################################\n";
   printf "%-3s %-73s %-2s"," #","$a","#";
   print  "\n########################################",
                            "########################################\n";
   } else {
         printf "%-3s %-73s %-3s\n", "#####", "$a", "#####";
   }
}


# ===========================================================================
# Mini-Titelleiste erzeugen
# ===========================================================================
#sub minititel {
#   my ($a) = @_;
#    printf "%-3s %-73s %-3s\n", "#", "$a", "#";
# }

# ===========================================================================
# Beliebige Liste mit beliebigem Trennzeichen in einen String schreiben
# ===========================================================================

# ????????????????????

sub formatiere_liste {
   my ($trenner,@liste) = @_;
   # print "Trenner $trenner  Liste: -@liste-\n\n";
   my $on_off=0;
   my $returnstring="";
   my $listitem="";
   foreach $listitem (@liste) {
      if ($listitem eq "") {
         next;
      }
      if ($on_off==0) {
         # erster Durchlauf
         $returnstring=$listitem;
         $on_off=1;
      } else {
         # weitere Durchläufe
         $returnstring="$returnstring"."$trenner"."$listitem";
      }
   }
   # print "Ret: $returnstring\n";
   return $returnstring;
 }




################################################################################
# Zentrale Dateirechte
################################################################################
=pod

=item I<get_alle_verzeichnis_rechte()>

Reads all directory permissions from repair.directories and displays
puts them in a hash.

=cut
sub get_alle_verzeichnis_rechte {
   # Diese Datei liest repair-directories ein in einen Hash
   # Key: Verzeichnis, exakt so, wie es in repair.directories steht
   # Value: die entsprechende Zeile in repair.directories
   # Hash alle_verzeichnis_rechte muss global sein
   %alle_verzeichnis_rechte=();
   my $verzeichnis="";
   my $owner="";
   my $gowner="";
   my $permissions="";
   my $key="";
   my $value="";
   open(REPAIR, "<$DevelConf::devel_pfad/repair.directories");
   while (<REPAIR>) {
      chomp(); # Returnzeichen abschneiden
      s/\s//g; # Spezialzeichen raus
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($verzeichnis,$owner,$gowner,$permissions)=split(/::/);
      $alle_verzeichnis_rechte{$verzeichnis}=$_;
   }
   close(REPAIR);
   
   if($Conf::log_level>=3){
      # Hash ausgeben
      while (($key,$value) = each %alle_verzeichnis_rechte){
         printf "%-40s %40s\n","$key","-$value-";
      }
    }

}




=pod

=item I<get_alle_v_rechte()>

Liest die Rechte aus dem Hash von get_alle_verzeichnis_rechte aus
Parameter ist das Verzeichnis, so wie es in repair.directories steht
Wenn ein $-Zeichen im Parameter steht, muss das Escape-Zeichen verwendet werden

Beispiel:  

my ($owner,$gowner,$perm)=get_v_rechte("/home/lehrer/\$lehrer");

=cut
sub get_v_rechte {
   my ($key)=@_;
   if (not exists($alle_verzeichnis_rechte{$key})) {
      print "ABBRUCH: Dateirechte von $key konnten nicht ermittelt werden!\n\n";
      exit;
   } 
   my $linie=$alle_verzeichnis_rechte{$key};
   my ($verzeichnis,$owner,$gowner,$permissions)=split(/::/,$linie);
   if($Conf::log_level>=3){
      print "Verzeichnis: $verzeichnis\n";
      print "Eigentümer: $owner\n";
      print "Gruppe: $gowner\n";
      print "Rechte: $permissions\n";
    }
   my @v_rechte=($owner,$gowner,$permissions);
   return @v_rechte;
}



=pod

=item I<setup_verzeichnis(...)>

Todo

=cut
sub setup_verzeichnis {
   my ($key,$pfad,$user,$gruppe)=@_;
   # key: woher in repair.directories soll ich Rechte und owner holen
   # pfad: auf welches Verzeichnis soll angewendet werden 
   # user: mit welchem username soll $schueler bzw. $lehrer ersetzt werden
   # gruppe: mit welcher Gruppe soll $klasse ersetzt werden
   if (not exists($alle_verzeichnis_rechte{$key})) {
      print "ABBRUCH: Dateirechte von $key konnten nicht ermittelt werden!\n\n";
      exit;
   }

   if ($pfad eq ""){
      print "\nABBRUCH: Parameter 2 von setup_verzeichnis fehlt.\n\n";
      exit;
   }    
      my $linie=$alle_verzeichnis_rechte{$key};
      my ($verzeichnis,$owner,$gowner,$permissions)=split(/::/,$linie);
      
      # Ersetzungen durchführen
      # wenn mehrere duch / getrennte Dateirechte, dann erste nehmen
      if ($permissions =~m/\//) {
         ($permissions)=split(/\//,$permissions);
      }
      # $webuser ersetzten
      $owner=~s/\$webuser/$DevelConf::apache_user/;
      # $webserver ersetzten
      $pfad=~s/\/\$webserver/$DevelConf::apache_root/;
      # $samba ersetzten
      $pfad=~s/\/\$samba/$DevelConf::samba_dir/;

      # user einbinden
      if (defined $user) {
          $owner=$user;
      }

      # user einbinden
      if (defined $gruppe) {
          $gowner=$gruppe;
      }



    if($Conf::log_level>=3){
      print "Benutze Rechte von          $verzeichnis\n";
      print "Zu setztender Eigentümer:   $owner\n";
      print "Zu setztende Gruppe:        $gowner\n";
      print "Zu setztende Rechte:        $permissions\n";
      print "Wende an auf Verzeichnis:   $pfad\n";
      
    }
  
    # vorhandene Daten prüfen
   if (not -e $pfad) {
      if($Conf::log_level>=2){
        print "Lege $pfad an.\n";
      }
      &do_falls_nicht_testen(
        "mkdir $pfad"
      );
   } elsif (-l $pfad) {
      print "ABBRUCH: $pfad ist ein Link auf ein Verzeichnis\n";
      exit;
   } elsif (-d $pfad) {
      if($Conf::log_level>=2){
         print "Verzeichnis $pfad ist schon vorhanden\n";
       }
   } else {
      print "ABBRUCH: $pfad existiert, ist jedoch kein Verzeichnis\n\n";
      exit;
   }

   # Rechte und Owner setzten   
   if ($DevelConf::testen==0) {
     if($Conf::log_level>=2){
        print "Setze $pfad auf $permissions $owner.$gowner\n\n";
      }
     system("chown ${owner}.${gowner} $pfad");
     system("chmod $permissions $pfad");
   }

  
}




# ===========================================================================
# ausgabe vom loglevel abhängig machen
# ===========================================================================

#sub ausgabe{
#    my ($level,$art,$ausgabe)=@_;
#      # 1. Argument numerisch: ab welchem loglevel erfolgt Augabe
#      # 2. Argument string   : string der ausgegeben wird
#      # 3. Art:       test   : Nur als Text
#      #              titel   : Als großer Titel
#      #          minititel   : Als kleiner Titel
#      #
#      # Zum debuggen
#      # print "Ab Level $level ausgeben\n";
#      # print "log_level:","$Conf::log_level\n";
#    if ($level<=$Conf::log_level){
#       if ($art eq "text")       {print "$ausgabe\n"}
#       if ($art eq "minititel")  {&titel("$ausgabe")}
#       if ($art eq "titel")      {&titel("$ausgabe")}
#       if ($art eq "befehl")      {$ausgabe}
#  
#       # befehle
#    }
#}


# ===========================================================================
# Hash mit allen Schülern in schueler.ok/user.ok (identifier) und deren Klasse
# ===========================================================================

# ????????????? deprecated
sub schueler_ok_hash {
  my $k;
  my $v;
  open(USEROK, 
       "${DevelConf::ergebnis_pfad}/${DevelConf::schueler_oder_user}.ok") 
       || die "Fehler: $!";
  while(<USEROK>){
    # identifier erzeugen aus schueler.ok
    ($feld1,$feld2,$feld3,$feld4)=split(/;/);
    $identifier_schueler_ok=join("",($feld2,";",$feld3,";",$feld4));
    # Hash-Tabelle erzeugen 
    $schueler_ok_hash{$identifier_schueler_ok}="$feld1";
  }
  close(USEROK);

  # Ausgabe aller Schüler, die in Zukunft im System sein werden (schueler.ok/user.ok),
  # mit ihrer Klasse
  if($Conf::log_level>=3){
     &titel("Gebe den Inhalt von  an ${DevelConf::schueler_oder_user}.ok... und die Klassen");
     print("Schüler in ${DevelConf::schueler_oder_user}.ok:",
           "                                      Klasse:\n");
     print("===========================================================================\n");
     while (($k,$v) = each %schueler_ok_hash){
       printf "%-60s %3s\n","$k","$v";
     }
   }
  return %schueler_ok_hash;
}


# ===========================================================================
# Hash mit ALLEN Loginnamen 
# ===========================================================================
=pod

=item I<%hash = user_login_hash()>

Returns a hash with all user loginnames.

=cut
sub  user_login_hash{
  while(($login_name_im_system)=getpwent) {    
     # Alle bisher vorhandnen Loginnamen in passwort-Hash
     $user_login_hash{$login_name_im_system}="vorhanden";                                    
   };

  # Ausgabe aller Loginnamen, die schon vorhanden sind
  if($Conf::log_level>=3){
     #&titel("Vorhandene Login-Namen");
     print("Login-Name:                                                       Status:\n");
     print("===========================================================================\n");
     while (($k,$v) = each %user_login_hash){
       printf "%-60s %3s\n","$k","$v";
      }
  }
return %user_login_hash;
}



# ===========================================================================
# Daten aus Klassen-Tauschverzeichnis ins home des Schülers kopieren
# ===========================================================================
=pod

=item I<%hash = save_tausch_klasse(login, klasse)>

Daten aus Klassen-Tauschverzeichnis ins home des Schülers kopieren

=cut

sub save_tausch_klasse {
   my ($login, $klasse) = @_;
   my $dirname=&zeit_stempel;
   my @entry = getpwnam($login);
   my $homedir = "$entry[7]";
   my $dirpath="$homedir"."/windows/"."Klassen-Tausch-"."$dirname"."/";

   my $tausch_klasse_path = "";
   if ($klasse eq "lehrer") {
     $tausch_klasse_path = "/home/tausch/lehrer";
   } else {
     $tausch_klasse_path = "/home/tausch/klassen/"."$klasse";
   }
   # abs. Pfade der zu movenden Verzeichnisse im Tauschverzeichnis 
   # in eine Liste schreiben
   print "Hierher moven (Home des Schülers/lehrers): \n   $dirpath\n";
   print "Hier suchen (Klassen-Tausch/Lehrer-Tausch):\n   $tausch_klasse_path\n";

   if (not -e "$tausch_klasse_path"){
     # nit tun
   } else {
   opendir KTAUSCH, $tausch_klasse_path or 
                  die "kann $tausch_klasse_path nicht öffnen\n";

   foreach my $datei (readdir KTAUSCH){
      if ($datei eq "."){next};
      if ($datei eq ".."){next};
      my $path=("$tausch_klasse_path"."/"."$datei");
      my @statliste=lstat($path);
      my $owner = getpwuid $statliste[4];
      print "Gefunden: $datei gehört $owner\n";
      # wenn die Datei/Verzeichnis dem zu versetztenden gehört
      # Todo: UND bei Verzeichnissen kein weiterer owner unterhalb auftritt ???????
      if ($owner eq "$login") {
      # Verschieben
      if (not -e "$dirpath") {
         &do_falls_nicht_testen(
           "install -d -o$login -glehrer $dirpath"
          );
      };
            print "Verschieben: $datei (owner: $owner)\n";
        &do_falls_nicht_testen(
           "mv \"$path\" $dirpath"
        );
      }
   }
   closedir KTAUSCH;
}
}


# ===========================================================================
# Schülergruppe anlegen und Verzeichnisse erstellen
# ===========================================================================
=pod

=item I<%hash = neue_linux_gruppe_schueler(klasse)>

Unterschied zu provide_class_files und add_class_to_sys ????

=cut
sub neue_linux_gruppe_schueler {
    # legt Klasse und Verzeichnisse an
    my ($gruppe) = @_;
    my $klassen_homes = "/home/schueler/${gruppe}";
    #my $schueler_homes = "/home/schueler/${gruppe}";
    my $klassen_tausch = "/home/tausch/klassen/${gruppe}";
    my $klassen_aufgaben = "/home/aufgaben/${gruppe}";
    my $smb_musterklasse = "${DevelConf::samba_dir}/netlogon/klasse.bat";
    my $smb_klasse = "${DevelConf::samba_dir}/netlogon/${gruppe}.bat";
#    my $web_klasse = "${DevelConf::apache_root}/userdata/${gruppe}";

    #--------------------------------------------------
    # die Gruppe anlegen
    # LDAP
    &add_class_to_sys($gruppe);
#    &do_falls_nicht_testen(
#         "groupadd $gruppe"
#    ); 

    #--------------------------------------------------
    # Klassen-Verzeichnis für die homes erstellen
    if ($DevelConf::testen==0) {
    &setup_verzeichnis("/home/schueler/\$klassen",
                       "$klassen_homes");
    &setup_verzeichnis("/home/tausch/klassen/\$klassen",
                       "$klassen_tausch");
    # Aufgaben-Verzeichnis anlegen
    &setup_verzeichnis("/home/aufgaben/\$klassen",
                       "$klassen_aufgaben");

    }

    &do_falls_nicht_testen(
#         "cp -af  $smb_musterklasse $smb_klasse"
    );
}




=pod

=item I<provide_class_files(class)>

Creates all files and directories for a class (exchange directories).

=cut


sub provide_class_files {
    my ($class) = @_;
    my $klassen_homes="/home/schueler/$class";
    my $klassen_tausch="/home/tausch/klassen/$class";
    my $klassen_aufgaben="/home/aufgaben/$class";
    &setup_verzeichnis("/home/schueler/\$klassen",
                    "$klassen_homes");
    &setup_verzeichnis("/home/tausch/klassen/\$klassen",
                    "$klassen_tausch");
    &setup_verzeichnis("/home/aufgaben/\$klassen",
                    "$klassen_aufgaben");
}


#sub provide_class {
#    my ($class) = @_;
#    my $klassen_homes="/home/schueler/$class";
#    my $klassen_tausch="/home/tausch/klassen/$class";
#    my $klassen_aufgaben="/home/aufgaben/$class";
#    &setup_verzeichnis("/home/schueler/\$klassen",
#                    "$klassen_homes");
#    &setup_verzeichnis("/home/tausch/klassen/\$klassen",
#                    "$klassen_tausch");
#    &setup_verzeichnis("/home/aufgaben/\$klassen",
#                    "$klassen_aufgaben");
#
#    &add_class_to_sys($class);
#    #&do_falls_nicht_testen(
#    #   "groupadd $class",
#    #);
#}









# ===========================================================================
# Verzeichnisse erstellen für lehrer
# ===========================================================================

# alle schon vorhanden

#sub neue_linux_gruppe_lehrer {
#    # Web-verzeichnis für die Lehrer anlegen
#    my $web_lehrer = "${DevelConf::apache_root}/userdata/lehrer";
#    if (not (-e "$web_lehrer")){
#        &do_falls_nicht_testen(
#             "mkdir $web_lehrer",
#             "chown ${DevelConf::apache_user}.root $web_lehrer",
#             "chmod 0501 $web_lehrer"
#        );
#      }


#}




# ===========================================================================
# Links für neuen schueler anlegen
# ===========================================================================
=pod

=item I<%hash = user_links(login, klasse, klasse-alt)>

Legt links an für den Schüler.

=cut
sub user_links {
  my($login, $gruppe, $alt_gruppe) = @_;
  # $alt_gruppe beim Versetzen
  my $tausch_klasse="";
  my $user_home = "";


  if ($gruppe ne "lehrer"){
    $tausch_klasse="/home/tausch/klassen/$gruppe";
    $user_home = "/home/schueler/$gruppe/$login";
  } else {
    $tausch_klasse="/home/tausch/lehrer";
    $user_home = "/home/lehrer/$login";
  }

  # Verzeichnis Tauschverzeichnisse löschen
  if (defined $alt_gruppe) {
     &do_falls_nicht_testen(
          "rm -rf $user_home/Tauschverzeichnisse"

     );
  }
  
  if ($gruppe eq "lehrer" && $alt_gruppe eq "speicher") {
      # nichts tun
  }
  else {
     # normales Versetzten (auch lehrer -> speicher)
     # sicherstellen dass Verzeichnis Tauschverzeichnisse existiert
     &setup_verzeichnis("/home/schueler/\$klassen/\$schueler/Tauschverzeichnisse",
                      "$user_home/Tauschverzeichnisse");

     # Links zu Tauschverzeichnissen anlegen
     &do_falls_nicht_testen(
         # Link auf Klassentausch anlegen
          "ln -sf  $tausch_klasse $user_home/Tauschverzeichnisse/Tausch-$gruppe",
          # Link auf Schülertausch anlegen
          "ln -sf /home/tausch/schueler $user_home/Tauschverzeichnisse/Tausch-Schule"
     );

  }
}



# ===========================================================================
# Protokoll-Datei lesen
# ===========================================================================
=pod

=item I<%hash = protokoll_linien()>

liest die Linien aus user.protokoll in einen Hash.

=cut
sub protokoll_linien {
   # Protokoll-Datei Zeilenweise in einen Hash einlesen
   my %protokoll_linien=();
   open(PROTOKOLL,"<$DevelConf::protokoll_datei");
   # Einlesen in einen Hash
     while(<PROTOKOLL>){
        # Return entfernen
        chomp();
        $protokoll_linien{$_}="";
      }
   close(PROTOKOLL);
   # Rückgabe des Hashes (key=Linie, Value nicht definiert)
   return %protokoll_linien;  
}


# ===========================================================================
# Datei extrakurse.schueler erzeugen aus extrakurse.txt 
# ===========================================================================
=pod

=item I<extra_kurs_schueler(tag, monat, jahr)>

Datei extrakurse.schueler erzeugen aus extrakurse.txt. tag, monat,
jahr soll das aktuelle Datum sein. Es werden nur Schüler derjenigen
Kurse erzeugt, deren Kusr-Ende-Datum noch nicht erreicht ist.

=cut
sub extra_kurs_schueler {
  my ($tag, $monat, $jahr) = @_;
  my $kursname;
  my $user_basisname;
  my $user_anzahl;
  my $entfern_datum;
  my $gecos;
  my $passwort;
  my $entfern_tag;
  my $entfern_monat;
  my $entfern_jahr;
  my $wunsch_login;
  my $usernummer="nix";
  my $i;
  my $i_mod;
  my $datum_epoche;
  my $entfern_datum_epoche;
  my $identifier; 
  my %generated_identifiers=();
  my %generated_kurs=();
  open(EXTRAKURSESCHUELER, ">${DevelConf::ergebnis_pfad}/extrakurse.schueler") 
       || die "Fehler: $!";

  open(EXTRAKURSE, "<${DevelConf::config_pfad}/extrakurse.txt") 
       || die "Fehler: $!";

  &titel("Reading ${DevelConf::config_pfad}/extrakurse.txt ...");

  while(<EXTRAKURSE>){
     my $datum="";
     chomp();
     if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
     if($_ eq ""){next}; # Bei Leerzeilen aussteigen
     print("-----------------------------------------------------------------------------\n");
     print("Extrakurs: \n$_\n");
     ($kursname, 
      $user_basisname, 
      $user_anzahl, 
      $datum, 
      $gecos, 
      $passwort,
      $entfern_datum)=split(/;/);
     ($entfern_tag, $entfern_monat, $entfern_jahr)=split(/\./, $entfern_datum);


 
     # $user_anzahl muss aus Ziffern bestehen
     if ($user_anzahl=~/[^0-9]/){
           # 
           print "\n\n\nSYNTAXFEHLER!\n";
           print "\n\n  Benutzer-Anzahl  $user_anzahl  enthält nicht nur Ziffern ";
           print "(Kurs  $kursname)\n\n";
           print "\n\n  Beheben sie diesen Fehler in /etc/sophomorix/user/extrakurse.txt\n\n";
           print "\n\n  Und starten sie das Programm neu.\n\n";
           # Programm beenden
              exit;
       }

     # Prüfen, ob entfern-Datum überschritten ist
     ## Achtung, Januar=0

     # Datum zu Programmstart (ohne Minuten und Sekunden)
     $datum_epoche=timelocal(0, 0, 0, $tag , ($monat-1), $jahr);
     if($Conf::log_level>=3){
        print("  Unix-Datum   Heute :   $datum_epoche\n");
      }
     # Datum ab dem entfernt werden soll (ohne Minuten und Sekunden)
     $entfern_datum_epoche=timelocal(0, 0, 0, $entfern_tag , $entfern_monat-1, $entfern_jahr);
     if($Conf::log_level>=3){
        print("  Unix-Entfern-Datum :   $entfern_datum_epoche\n");
      }
     # Wenn Entfern-Datum ÜBERSCHRITTEN, dann nächste Zeile
     if ($datum_epoche>$entfern_datum_epoche){
         print("  Entfern-Datum ist überschritten ...\n");
         next;
      }; # Nächste Zeile einlesen

     print("  User werden generiert ...\n");
     # Loginzeilen für den Kurs generieren
     for ($i=1;$i<=$user_anzahl;$i++){
       # Wunschlogin erzeugen
       if ($i<=9){
           $i_mod="0"."$i" # Null davorhängen
         } else {
           $i_mod=$i;      # keine Null davor
         }
       $wunsch_login="$user_basisname"."$i_mod";
       # identifier ermitteln
       $identifier="$i_mod".";"."$gecos".";"."$datum";

       #print "\n$identifier\n\n";

       # prüfen, ob identifier schon vorhanden -> Abbruch mit Info
         if (exists ($generated_identifiers{$identifier})) {
            print "\n\nFehler beim Erzeugen der Schüler des Extrakurses $kursname !\n";
            print "Erzeugt werden sollte im Kurs --$kursname-- der User-Identifier:\n\n";     
            print "    $identifier\n";
            print "\nDieser wurde jedoch im Kurs --$generated_identifiers{$identifier}-- schon erzeugt.\n";
            print "\n\nAbhilfe:\n";
            print "\nIn den beiden Zeilen der Kurse $kursname bzw. $generated_identifiers{$identifier} \n";
            print "müssen sich das gecos-Feld ($gecos) \nODER das Anlegedatum ($datum) unterscheiden.\n";
            print "Korrigieren Sie dies im noch nicht angelegten Kurs.\n";
            exit;
         }

       # prüfen, ob Kurs schon vorhanden -> Abbruch mit Info
         if (exists ($generated_kurs{$kursname})) {
            print "\n\nFehler beim Erzeugen des Kurses $kursname !\n";
            print "Der Kursname $kursname kommt in extrakurse.txt doppelt vor.\n";
            print "Korrigieren Sie dies im noch nicht angelegten Kurs.\n";
            exit;
         }

       # identifier ins Hash schreiben
       $generated_identifiers{$identifier}="$kursname";

       # uncomment to debug
       #while (($k,$v) = each %generated_identifiers) {
       #    printf "%-35s %3s\n","$k","$v";
       #}
     
       # Zeile in Datei schreiben 
       print EXTRAKURSESCHUELER ("$kursname".";".
                                "$i_mod".";".# Nummer nutzen für untersch. identifier
                                "$gecos".";".
                                "$datum".";".  # Entferndatum
                                "$wunsch_login".";".
                                "$passwort".";".
                                "\n");
      } # Ende Zeilenerzeugung

      # kursname ins Hash schreiben
      $generated_kurs{$kursname}="";

}

close(EXTRAKURSE);


close(EXTRAKURSESCHUELER);
}



# ===========================================================================
# lehrer.txt ordnen
# ===========================================================================
=pod

=item I<lehrer_ordnen()>

Liest lehrer.txt und schreibt sie tabuliert wieder.

=cut
sub lehrer_ordnen {
   my $typ="";
   my $nachname="";
   my $vorname="";
   my $datum="";
   my $wunsch_login="";
   my $erst_passwort="";
   my $lehrer_kuerzel="";
   my $quota="";

   my $identifier="";

   my @linien=();
   my @linien_sortiert=();
   if($Conf::log_level>=3){
      &titel("Ordne die Datei lehrer.txt ...");
   }

   open (LEHRER, "${DevelConf::users_pfad}/lehrer.txt") 
         || die "Fehler: ${DevelConf::users_pfad}/lehrer.txt \n$!";

   open (LEHRERTMP, ">${DevelConf::users_pfad}/lehrer.tmp") 
         || die "Fehler: $!";


   # Infotext für die Datei lehrer.txt
   # Achtung: folgende Einträge werden ASCIIbetisch geordnet!
#   print LEHRERTMP ("! Lehrer mit vorangesetzem # bleiben unberücksichtigt.\n");
#   print LEHRERTMP ("! \n");
#   print LEHRERTMP ("* Bei schon angelegten Lehrern dürfen die ersten 6 Felder NICHT mehr verändert werden\n");
#   print LEHRERTMP ("* A******************************************************************************\n"); 
#   print LEHRERTMP ("* Z******************************************************************************\n"); 


   while(<LEHRER>) {
     chomp();

#
#     if(/^\!/){next;} # Bei Kommentarzeichen ! aussteigen (Für Informationen)
#     if(/^\*/){next;} # Bei Kommentarzeichen ! aussteigen (Für Informationen)

     if(/^\#/){
        # Bei Kommentarzeichen # unbearbeitet übernehmen
        print LEHRERTMP ("$_\n");
        # weiter mit nächstem Lehrer
        next;
      } 
      s/\s//g;
      # Wenn Zeile Leer, dann aussteigen
      if ($_ eq ""){
         next;
      } 
     ($typ,
      $nachname,
      $vorname,
      $datum,
      $wunsch_login,
      $erst_passwort,
      $lehrer_kuerzel,
      $quota)=split(/;/);

      # identifier erzeugen
      $identifier=join("",
                       ($nachname,
                       ";",
                        $vorname,
                       ";",
                        $datum));

      if($Conf::log_level>=2){
         print ("    $identifier\n");
      }
      # In lehrer.txt muss IMMER der gültige Loginname stehen (wegen Quota) 

     if ($wunsch_login eq "") {
         # gibt es lehrer schon im system, dann dort login holen
         print("\n\n\nAbbruch:\n\n");
         print("Für die Lehrerin/den Lehrer  $vorname $nachname   ist kein Login-Name angegeben!\n\n");

         print("\n\n  Wenn   $vorname $nachname   SCHON ANGELEGT ist, muss der im System eingetragene \n");
         print("  Login-Name auch in lehrer.txt eingetragen werden  \n\n");

         print("\n\n  Wenn   $vorname $nachname   NOCH NICHT ANGELEGT ist, kann ein beliebiger\n");
         print("  Login-Name in lehrer.txt eingetragen werden  \n\n");

        exit;

# evtl .   ???????????????
# Diese Manuelle Eingabe kann evtl. automatisiert werden

# Wenn: Script von Helmut Krämer eine lehrer.protokoll erzeugt, könnte aus dieser der 
# identifier und der zugehörige Login ermittelt werden
# dies gilt nur für den Umstieg, ansonsten soll lehrer.txt eine Datei bleiben, die das erste mal aus dem 
# Schulverwaltungsprogramm geholt wird und dann: nur noch von Hand editieren


#       if (exists ($lehrer_im_system_loginname{$idenifier})){
#         print("\n\n $identifier gibt es !!!\n\n");
#       } else {
#         print("\n\n $identifier gibt es nicht\n\n");
#       }



         # lehrer nicht im System gefunden -> neuer lehrer
         # login muss angegeben werden, sonst Abbruch


#         print ("Bei einem Lehrer MUSS ein Wunsch-Login angegeben werden\n");
#         exit;
#         $wunsch_login="wunschlogin";
       }


     # Füllen der Felder
     if ($erst_passwort eq "") {
         $erst_passwort="erstpw";
     }


     if (not defined $lehrer_kuerzel) {
         $lehrer_kuerzel="kurz";
     }

     if ($lehrer_kuerzel eq "") {
         $lehrer_kuerzel="kurz";
     }

     if (not defined $quota) {
         $quota="quota";
     }

     if ($quota eq "") {
         $quota="quota";
     }


     # geordnete Zeile ausgeben
     printf LEHRERTMP ("%-6s %-14s %-14s %-11s %-8s %-8s %-4s %-6s",
           "$typ",
           ";$nachname",
           ";$vorname",
           ";$datum",
           ";$wunsch_login",
           ";$erst_passwort",
           ";$lehrer_kuerzel",
           ";$quota");
     print LEHRERTMP (";\n");
   }
  
   close(LEHRER);
   close(LEHRERTMP);




   open (LEHRERTMP, "<${DevelConf::users_pfad}/lehrer.tmp") 
       || die "Fehler: $!";
   while(<LEHRERTMP>) {
       # ab ins array
       push @linien, $_;
     }
   close(LEHRERTMP);

 
   # alphabetisch sortieren
   @linien = sort @linien;

   open (LEHRER, ">${DevelConf::users_pfad}/lehrer.txt") 
         || die "Fehler: $!";
     #print LEHRER ("@linien_sortiert");
   
     while (@linien) {
        $a=shift(@linien);
        print LEHRER "$a";
      }
   close(LEHRER);


   system("rm ${DevelConf::users_pfad}/lehrer.tmp");
   system("chmod 700 ${DevelConf::users_pfad}/lehrer.txt");
   if($Conf::log_level>=3){  
      &titel("... Datei lehrer.txt ist geordnet.");
   }
}


# ===========================================================================
# Hash mit User-Loginname und Identifier erzeugen
# ===========================================================================

# deprected

sub user_login_ident {
     my $klasse_protokoll="";
     my $name_protokoll="";
     my $loginname_protokoll="";
     my $passwort_protokoll="";
     my $geburtsdatum_protokoll="";
     my $vorname_protokoll="";
     my $nachname_protokoll="";
     my $identifier_protokoll="";
     my %user_login_ident=();
     my $k="";
     my $v="";
   # Einlesen der Protokolldatei
   open(PROTOKOLL, "$DevelConf::protokoll_datei") || die "Fehler: $!";
   while(<PROTOKOLL>){
     chomp($_); # Newline abschneiden

      # Protokolldateien bearbeiten
     ($klasse_protokoll, 
      $name_protokoll,
      $loginname_protokoll,
      $passwort_protokoll,
      $geburtsdatum_protokoll
     )=split(/;/);

     # Name aufsplitten
     ($vorname_protokoll,$nachname_protokoll)=split(/ /,$name_protokoll);
     # Zusammenhängen zu identifier
     $identifier_protokoll=join("",
                               ($nachname_protokoll,
                                ";",
                                $vorname_protokoll,
                                ";",
                                $geburtsdatum_protokoll));

     #print("$loginname_protokoll   $identifier_protokoll\n");
  
     # In einen Hash schreiben: mit loginnamen als Key 
     #$user_login_ident{$identifier_protokoll}="$loginname_protokoll";
     $user_login_ident{$loginname_protokoll}="$identifier_protokoll";

   }

   close(PROTOKOLL);

   # Ausgabe aller Lehrer, die im System sind (schueler.protokoll/user.protokoll),
   # mit ihrem Login
   if($Conf::log_level>=3){
      print("Loginname:           Identifier:\n");
      print("===========================================================================\n");
      while (($k,$v) = each %user_login_ident){
        printf "%-20s %3s\n","$k","$v";
      }
    }
  return %user_login_ident;
}





# ===========================================================================
# Hash mit Identifier und User-Loginname erzeugen
# ===========================================================================

# deprecated

sub user_ident_login {
# fuer ldap nicht mehr noetig
     my $klasse_protokoll="";
     my $name_protokoll="";
     my $loginname_protokoll="";
     my $passwort_protokoll="";
     my $geburtsdatum_protokoll="";
     my $vorname_protokoll="";
     my $nachname_protokoll="";
     my $identifier_protokoll="";
     my %user_login_ident=();
     my $k="";
     my $v="";
   # Einlesen der Protokolldatei
   open(PROTOKOLL, "$DevelConf::protokoll_datei") || die "Fehler: $!";
   while(<PROTOKOLL>){
     chomp($_); # Newline abschneiden

      # Protokolldateien bearbeiten
     ($klasse_protokoll, 
      $name_protokoll,
      $loginname_protokoll,
      $passwort_protokoll,
      $geburtsdatum_protokoll
     )=split(/;/);

     # Name aufsplitten
     ($vorname_protokoll,$nachname_protokoll)=split(/ /,$name_protokoll);
     # Zusammenhängen zu identifier
     $identifier_protokoll=join("",
                               ($nachname_protokoll,
                                ";",
                                $vorname_protokoll,
                                ";",
                                $geburtsdatum_protokoll));

     #print("$loginname_protokoll   $identifier_protokoll\n");
  
     # In einen Hash schreiben: mit identifier als Key 
     $user_login_ident{$identifier_protokoll}="$loginname_protokoll";
     #$user_login_ident{$loginname_protokoll}="$identifier_protokoll";

   }

   close(PROTOKOLL);

   # Ausgabe aller Lehrer, die im System sind (schueler.protokoll/user.protokoll),
   # mit ihrem Login
   if($Conf::log_level>=3){
      print("Identifier:                              Loginname:\n");
      print("===========================================================================\n");
      while (($k,$v) = each %user_login_ident){
        printf "%-40s %-12s\n","$k","$v";
      }
    }
  return %user_login_ident;
}



# ===========================================================================
# Hash mit Lehrer-Identifier und Loginname erzeugen
# ===========================================================================

# deprecated

sub lehrer_ident_login {
     my $klasse_protokoll="";
     my $name_protokoll="";
     my $loginname_protokoll="";
     my $passwort_protokoll="";
     my $geburtsdatum_protokoll="";
     my $vorname_protokoll="";
     my $nachname_protokoll="";
     my $identifier_protokoll="";
     my %lehrer_im_system_loginname=();
     my $k="";
     my $v="";
   # Einlesen der Protokolldatei
   open(PROTOKOLL, "$DevelConf::protokoll_datei") || die "Fehler: $!";
   while(<PROTOKOLL>){
     chomp($_); # Newline abschneiden

      # Protokolldateien bearbeiten
     ($klasse_protokoll, 
      $name_protokoll,
      $loginname_protokoll,
      $passwort_protokoll,
      $geburtsdatum_protokoll
     )=split(/;/);

     # Name aufsplitten
     ($vorname_protokoll,$nachname_protokoll)=split(/ /,$name_protokoll);
     # Zusammenhängen zu identifier
     $identifier_protokoll=join("",
                               ($nachname_protokoll,
                                ";",
                                $vorname_protokoll,
                                ";",
                                $geburtsdatum_protokoll));

     print("$identifier_protokoll      $loginname_protokoll   \n");
  
     # In einen Hash schreiben: mit loginnamen als Wert (um Löschen herauszufinden)
     $lehrer_im_system_loginname{$identifier_protokoll}="$loginname_protokoll";
   }

   close(PROTOKOLL);

   # Ausgabe aller Lehrer, die im System sind (schueler.protokoll/user.protokoll),
   # mit ihrem Login
   if($Conf::log_level>=3){
      print("Lehrer im System:                                           Login:\n");
      print("===========================================================================\n");
      while (($k,$v) = each %lehrer_im_system_loginname){
        printf "%-60s %3s\n","$k","$v";
      }
    }
  return %lehrer_im_system_loginname;
}




# ===========================================================================
# Zeitstempel erzeugen
# ===========================================================================
=pod

=item I<zeit_stempel()>

Gibt die Zeit zurück. Geht mit `` einfacher ToDo

=cut
sub zeit_stempel {
   # Startdatum in eine temporäre Datei schreiben
   system("date +%Y-%m-%d_%H-%M-%S > /tmp/starttime");

   # Startdatum wieder auslesen
   open(STARTTIME, "/tmp/starttime") || die "Fehler: $!";
   while(<STARTTIME>){
      chomp();
      $zeit=$_;
   }

   # Temporäre Datei wieder löschen
   system("rm /tmp/starttime");

   return $zeit;
}





# ===========================================================================
# System-Befehl ausführen
# ===========================================================================
=pod

=item I<do_falls_nicht_testen(systembefehl)>

Wenn $testen=0 ist, soll systembefehl ausgeführt werden ansonsten wird
systembefehl nur als String ausgegeben


=cut
sub do_falls_nicht_testen {
   my ($systembefehl) = "";
   my @liste = @_;
   foreach $systembefehl (@liste) {
      #print "\n\n\$testen ist $DevelConf::testen\n\n";
      if ($DevelConf::testen==0) {
         # Ausführen
         system("$systembefehl");
      } else {
         # Ausgeben
         print "Befehl (Test):   $systembefehl\n";
      }
 }
}



# ===========================================================================
# Hilfe für ALLE Scripte
# ===========================================================================
=pod

=item I<help_text_all()>

will be deprecated when man pages are finished

=cut
sub help_text_all {
   my @list = split(/\//,$0);
   my $scriptname = pop @list;
   print "NAME:   $scriptname [OPTION]\n\n";

   print "Hilfe zu $scriptname:\n\n";
   #help
   print "  -h, --help\n";
   print "     Diese Hilfe anzeigen.\n\n";


   print "Menge an Ausgabe-Informationen während des Programmablaufs:\n\n";
   # verbose
   print "  -v, --verbose\n";
   print "     mehr Informationen ausgeben.\n\n";

   print "  -vv, --verbose --verbose\n";
   print "     noch mehr Informationen ausgeben.\n\n";
}



# ===========================================================================
# Abbruchmeldung bei Fehlerhafter Optionsangabe
# ===========================================================================
=pod

=item I<check_options()>

Diese Subroutine bekommt als Argment den Parsewert der Funktion
GetOptions.  Ist dieser nicht 1, so wurde eine Fehlerhafte Option
vergeben

=cut
sub  check_options{
   my ($parse_ergebnis) = @_;
   if (not $parse_ergebnis==1){
      my @list = split(/\//,$0);
      my $scriptname = pop @list;
      print "\nSie haben bei der Eingabe der Optionen einen Fehler begangen.\n"; 
      print "Siehe Fehlermeldung weiter oben. \n\n";
      print "... $scriptname beendet sich.\n\n";
      exit;
   } else {
      if($Conf::log_level>=3){
         print "Alle Befehls-Optionen wurden erkannt.\n\n";
      }
   }

}



=pod

=item I<check_datei_exit(file)>

Bricht mit Fehlermeldung ab, wenn die übergebene Datei nicht existiert


=cut
sub check_datei_exit {
  my ($datei) = @_;
  # Name der aufrufenden Datei ermitteln
  my @list = split(/\//,$0);
  my $scriptname = pop @list;
  if (not (-e "$datei")) {
     print "\n  Die Datei\n\n";
     print "    $datei\n\n";
     print "  wurde nicht gefunden.\n\n";
     print "  Sie muss vorhanden sein.\n\n";
     print "  $scriptname beendet sich deshalb!\n\n";
     exit;
  } 
}



=pod

=item I<check_datei_touch(file)>

Legt leere Datei an, wenn die übergebene Datei nicht existiert

=cut
sub check_datei_touch {
  my ($datei) = @_;
  if (not (-e "$datei")) {
     print "\n  Die Datei ${datei} wird angelegt \n\n";
     system("touch ${datei}");
  } 
}



=pod

=item I<check_config_template(file)>

Kopiert template datei nach file, wenn file nicht existiert

=cut
sub check_config_template {
  my ($datei) = @_;
  my $etc_file=${DevelConf::config_pfad}."/".$datei;
  my $config_datei=${DevelConf::config_template_pfad}."/".$datei;
  if (not (-e "$etc_file")) {
      my $command="cp $config_datei $etc_file";
      print "   ### Creating file: \n   $command \n";
     system("$command");
  } 
}



=pod

=item I<check_verzeichnis_mkdir(dir)>

Legt Verzeichnis an, wenn nicht existiert

=cut
sub check_verzeichnis_mkdir {
  my ($verzeichnis) = @_;
  if (not (-e "$verzeichnis")) {
     if($Conf::log_level>=2){
        print "\n  Das Verzeichnis ${verzeichnis} wird angelegt \n\n";
     }
     system("mkdir ${verzeichnis}");
  } 
}



=pod

=item I<print_user_samba_data(login)>

Druckt wichtige Samba Daten des users login

=cut
sub print_user_samba_data {
    my ($login) = @_;
    my $samba="";
    my @samba_lines="";

          # samba
          # database independent
          print "Samba:\n";
          $samba=`pdbedit -v -u $login`;
          @samba_lines=split(/\n/,$samba);
	  foreach (@samba_lines){
#            s/\s//g;
            # ??? nur am ersten auftreten von : splitten
            my ($attr,$value)=split(/: /);
            $value=~s/\s//g;

	    if (/^Account Flags/){
              printf "   Account Flags    : %-47s %-11s\n",$value,$login;    
            }
	    if (/^Home Directory/){
              printf "   Home Directory   : %-47s %-11s\n",$value,$login;    
            }
	    if (/^Password last set/){
              printf "   Pwd last set     : %-47s %-11s\n",$value,$login;    
            }
	    if (/^Password can change/){
              printf "   Pwd can change   : %-47s %-11s\n",$value,$login;    
            }
	    if (/^Password must change/){
              printf "   Pwd must change  : %-47s %-11s\n",$value,$login;    
            }
	  }

}


=pod

=item I<get_user_history(login)>

Druckt die sophomorix Logfiles des users login aus 

=cut
sub get_user_history {
   my ($login) = @_;
   my @line=();
   my $count=0;
   &check_datei_touch("${DevelConf::log_files}/user-modify.log");
   open(HISTORY, 
       "<${DevelConf::log_files}/user-modify.log") 
        || die "Fehler: $!";

   while (<HISTORY>){
      chomp();
      @line=split(/::/);
      if (not defined $line[6]){$line[6]=""}
      if ($line[2] eq $login){
	 $count++;
         my $info=$line[0]."(".$line[1]."): ";
         printf "   %-27s %-55s \n",$info,$line[3];
         printf "      Unid: %-18s %-55s \n",$line[6],$line[5];
          
      }
   }
   close(HISTORY);
   if ($count==0){
       print "   No History exists.\n";
   }
}




=pod

=item I<get_group_list(login)>

Gibt die Liste der Gruppennamen zurück, in denen der user mit dem
loginnamen login ist.

=cut
sub get_group_list {
    my ($login) = @_;
    my @group_list=();
    my $pri_group_string=`id -gn $login`;
    my $group_string=`id -Gn $login`;
    chomp($group_string);
    chomp($pri_group_string);
    @group_list=split(/ /, $group_string);
    return @group_list;
}


=pod

=item I<print_forward(login,home)>

Gibt den Inhalt von .forward aus

=cut
# this sjould be true for all db and auth-systems
sub print_forward {
    my ($login, $home) = @_;
    if (-e "$home/.forward"){
       open(FORWARD,"$home/.forward");
       while (<FORWARD>){
           chomp();
	   print "   "."$_ \n";
       }
   } else {
       print "   User $login has no mail forwarding.\n";
   }
}



=pod

=item I<create_share_link(login,project)>

Legt ein Link an in das Tauschverzeichnis des Projekts an.

=cut
# this should be true for all db and auth-systems
sub create_share_link {
    my ($login,$project) = @_;
    print "Creating a link for user $login to project $project.\n";
    my $link_dir="/home/tausch/projects/${project}/";

    my($loginname_passwd,$passwort,$uid_passwd,$gid_passwd,$quota_passwd,
       $name_passwd,$gcos_passwd,$home,$shell)=&get_user_auth_data($login);

    my $link_name=$home."/Tauschverzeichnisse/Tausch-${project}";   
    my $link_target="/home/tausch/projects/${project}/";

    print "   Link name : $link_name\n";
    print "   Target    : $link_target\n";
    
    # create the link
    symlink $link_target, $link_name;
}

=pod

=item I<remove_share_link(login,project)>

Löscht den Link an in das Tauschverzeichnis des Projekts.

=cut
# this should be true for all db and auth-systems
sub remove_share_link {
    my ($login,$project) = @_;
    my($loginname_passwd,$passwort,$uid_passwd,$gid_passwd,$quota_passwd,
       $name_passwd,$gcos_passwd,$home,$shell)=&get_user_auth_data($login);
    my $link_name=$home."/Tauschverzeichnisse/Tausch-${project}";   
    print "Removing link: $link_name\n";
    # remove the link
    unlink $link_name;
}



=pod

=item I<zeit(epoche)>

Erzeugt Datum aus epochenzeit

=cut
sub zeit {
  my ($epoche)=@_;
  my $time=localtime($epoche);
  my $sekunden=$time->sec;
  my $min=$time->min;
  my $day=$time->mday;
  my $month=$time->mon+1;
  my $year=$time->year+1900;

  my $string="$day.$month.$year";
  #print "$string\n";
  return $string;
}


=pod

=item I<get_klasse_von_login(login)>

liefert die primäre Gruppe des übergebenen loginnamens (Ändert sich)

=cut
sub get_klasse_von_login {
  my ($loginname) = @_;
  my $gid=0;
  my $grname="";
  ($a,$a,$a,$gid) = getpwnam($loginname);
  ($grname) = getgrgid($gid); 
  # Klasse ermiteln
  #print "$gid ist in $grname\n";
  return $grname;
}




# Ende der Dokumentation


##############################################################################
# Ab hier bisher in sophomorix-libfür klassenmanager
##############################################################################

##############################################################################
# SCHÜLER
##############################################################################
# ===========================================================================
# Liste der Schüler einer Klasse ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion hat als Argument einen Gruppennamen
# Sie liefert alle Schüler dieser Klasse zurück
# Wenn keine Schüler in dieser Gruppe sind wird eine leere Liste zurückgegeben

sub get_schueler_in_klasse {
    my ($klasse)=@_;
    #print "$klasse<p>";
    my @pwliste=();
    my @userliste=();
    # Group-ID ermitteln
    my ($a,$b,$gid) = getgrnam $klasse; 
    #print"Info: Group-ID der Gruppe $klasse ist $gid<p>\n";

    # alle Schüler in dieser Gruppe heraussuchen
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis
     if ($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/schueler\//) {
         push(@userliste, $pwliste[0]);
         #print "$pwliste[3]";
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @userliste=sort @userliste;
    return @userliste;
}





# ===========================================================================
# Liste aller Schüler der Schule ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion liefert eine Liste aller Schüler der Schule zurück
sub get_schueler_in_schule {
    my @pwliste=();
    my @schuelerliste=();
    
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]";  # Das 8. Element ist das Home-Verzeichnis
      if ($pwliste[7]=~/^\/home\/schueler\//) {
         push(@schuelerliste, $pwliste[0]);
         #print "$pwliste[0]<p>";
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @schuelerliste = sort @schuelerliste;
    return @schuelerliste;
}

# ===========================================================================
# dito, aber im hash, Value ist primäre Gruppe
# ===========================================================================
sub get_schueler_in_schule_hash {
    my %schuelerhash=();
    my @liste=get_schueler_in_schule();
    foreach $user (@liste) {
    my ($nix,$nax,$nux,$gid) = getpwnam($user);
    my ($grname) = getgrgid($gid); 

       # Fülle den  Hash
       $schuelerhash{$user}="$grname";
    }
    return %schuelerhash;
}




################################################################################
# LEHRER
################################################################################
# ===========================================================================
# Liste aller Lehrer der Schule ermitteln, alphabetisch
# ===========================================================================
# Die Funktion liefert eine Liste aller Lehrer der Schule zurück
sub get_lehrer_in_schule {
    my @lehrerliste=();
    my @pwliste=();
    # Group-ID der Gruppe Lehrer ermitteln
    my @gruppenzeile=getgrnam "lehrer";
    my $gid=$gruppenzeile[2];
    #print"Info: Group-ID der Lehrer ist $gid<p>";

    setpwent();
    while (@pwliste=getpwent()) {
      #print "Prüfe user: $pwliste[0]<p>";
     if ($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/lehrer\//) {
         push(@lehrerliste, $pwliste[0]);
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @lehrerliste=sort @lehrerliste;
    #print"Lehrer sind: @lehrerliste <p>";
    return @lehrerliste;
}

# ===========================================================================
# dito, aber im hash
# ===========================================================================
sub get_lehrer_in_schule_hash {
    my %lehrerhash=();
    my @liste=get_lehrer_in_schule();
    foreach $user (@liste) {
       # Fülle den  Hash
       $lehrerhash{$user}="";
    }
    return %lehrerhash;
}



################################################################################
# WORKSTATIONS
################################################################################
# ===========================================================================
# Liste aller Workstations der Schule ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion liefert eine Liste aller Schüler der Schule zurück
sub get_workstations_in_schule {
    my @pwliste=();
    my @workstationliste=();
    
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]";  # Das 8. Element ist das Home-Verzeichnis
      if ($pwliste[7]=~/^\/home\/workstations\//) {
         push(@workstationliste, $pwliste[0]);
         #print "$pwliste[0]<p>";
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @workstationliste = sort @workstationliste;
    return @workstationliste;
}

# ===========================================================================
# dito, aber im hash
# ===========================================================================
sub get_workstations_in_schule_hash {
    my %workstationhash=();
    my @liste=get_workstation_in_schule();
    foreach $user (@liste) {
       # Fülle den  Hash
       $workstationhash{$user}="";
    }
    return %workstationhash;
}




# ===========================================================================
# Liste der Workstations eines Raumes ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion hat als Argument einen Raumnamen
# Sie liefert alle Workstations dieses Raumes zurück
# Wenn keine Workstations in diesem Raum sind wird eine leere Liste zurückgegeben
sub get_workstations_in_raum {
    my ($workstation)=@_;
    #print "$workstation<p>";
    my @pwliste=();
    my @workstations=();
    # Group-ID ermitteln
    my ($a,$b,$gid) = getgrnam $workstation; 
    #print"Info: Group-ID der Gruppe $workstation ist $gid<p>\n";

    # alle Workstations in diesem Raum heraussuchen
    setpwent();
    while (@pwliste=getpwent()) {
    #print"$pwliste[7]\n";  # Das 8. Element ist das Home-Verzeichnis
     if ($pwliste[3] eq $gid && $pwliste[7]=~/^\/home\/workstations\//) {
         push(@workstations, $pwliste[0]);
         #print "$pwliste[3]";
      }
    }
    endpwent();

    # Alphabetisch ordnen
    @workstations=sort @workstations;
    return @workstations;
}








################################################################################
# KLASSEN
################################################################################
# ===========================================================================
# Liste aller Klassen der Schule ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion liefert eine Liste aller Klassen der Schule zurück
sub get_klassen_in_schule {
    my @pwliste;
    my %klassen_hash=();
    my @liste;
    # Alle Klassen-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
       if ($pwliste[7]=~/^\/home\/schueler\//) {
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

# ===========================================================================
# dito, aber im hash
# ===========================================================================
sub get_klassen_in_schule_hash {
    my @pwliste;
    my %klassen_hash=();
    my @liste;
    # Alle Klassen-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
       if ($pwliste[7]=~/^\/home\/schueler\//) {
          $klassen_hash{getgrgid($pwliste[3])}=""; 
       }
    }
    endpwent();

    return %klassen_hash;
}


# ===========================================================================
# Prüfen,ob der übergebene Gruppenname(String) eine Klasse ist
# ===========================================================================
sub check_klasse {
    my ($klasse_to_check) = @_;
    # print "Pruefe, ob $klasse_to_check eine Klasse ist.";
    my @pwliste;
    my %klassen_id_hash=();
    # Alle Klassen-ids in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
       if ($pwliste[7]=~/^\/home\/schueler\//) {
          $klassen_id_hash{$pwliste[3]}=""; 
          #print "$pwliste[3]";
       }
    }
    endpwent();

    # Suche Group-ID zur zu prüfenden Gruppe
    my $gid=getgrnam("$klasse_to_check");
    if (not $gid) {$gid=-1};
    if (exists $klassen_id_hash{$gid}) {
        #print "$klasse_to_check ist eine Klasse";
        # Ja = 1
        $ergebnis=1;
    } else {
        # Nein =2
        $ergebnis=0;
    }
    return $ergebnis;
}





################################################################################
# RÄUME
################################################################################
# ===========================================================================
# Liste aller Raeume der Schule ermitteln, alphabetisch
# ===========================================================================
# Diese Funktion liefert eine Liste aller Raeume der Schule zurück
sub get_raeume_in_schule {
    my @pwliste;
    my %raeume_hash=();
    my @liste;
    # Alle Raeume-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
       if ($pwliste[7]=~/^\/home\/workstations\//) {
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



# Liest eine Liste mit den Räumen aus, in denen KA's stattfinden 
# können
sub get_ka_raeume_in_schule{
  my @ka_raum_liste=();
  if (-e "$DevelConf::config_pfad/ka-raeume.txt") {
     open(KARM,"$DevelConf::config_pfad/ka-raeume.txt");
     while (<KARM>) {
        chomp();
        push (@ka_raum_liste, $_);
     }
     close (KARM);
  } else {
    # print "not found";
    @ka_raum_liste=&get_raeume_in_schule();
  }

 return @ka_raum_liste;
}

# ===========================================================================
# dito, aber im hash
# ===========================================================================
sub get_raeume_in_schule_hash {
    my @pwliste;
    my %raeume_hash=();
    my @liste;
    # Alle Raeume-namen in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
       if ($pwliste[7]=~/^\/home\/workstations\//) {
          $raeume_hash{getgrgid($pwliste[3])}=""; 
       }
    }
    endpwent();

    return %raeume_hash;
}





# ===========================================================================
# Prüfen,ob der übergebene Gruppenname(String) ein Raum ist
# ===========================================================================
sub check_raum {
    my ($raum_to_check) = @_;
    # print "Prüfe, ob $raum_to_check ein Raum ist.";
    my @pwliste;
    my %raum_id_hash=();
    # Alle Raumn-ids in einen Hash

    setpwent();
    while (@pwliste=getpwent()) {
       if ($pwliste[7]=~/^\/home\/workstations\//) {
          $raum_id_hash{$pwliste[3]}=""; 
          #print "$pwliste[3]";
       }
    }
    endpwent();

    # Suche Group-ID zur zu prüfenden Gruppe
    my $gid=getgrnam("$raum_to_check");

    if (not $gid) {$gid=-1};
    if (exists $raum_id_hash{$gid}) {      
        if($Conf::log_level>=3){
           print "$raum_to_check ist ein Raum\n";
        }
        # Ja = 1
        $ergebnis=1;
    } else {
        if($Conf::log_level>=3){
           print "$raum_to_check ist KEIN Raum\n";
        }
        # Nein =0
        $ergebnis=0;
    }
    return $ergebnis;
}





# ===========================================================================
# Prüfen,ob der übergebene Name ein Lehrer ist
# ===========================================================================
sub check_lehrer {
  my $ergebnis=0;
  my ($name_to_check)=@_;
  if (&get_klasse_von_login($name_to_check) eq "lehrer") {  
        if($Conf::log_level>=3){
           print "$name_to_check ist ein Lehrer\n";
	 }
        # Ja = 1
        $ergebnis=1;
  } else {
        if($Conf::log_level>=3){
           print "$name_to_check ist KEIN Lehrer\n";
	 }
  }
  return $ergebnis
}


# ===========================================================================
# Hash mit Klassen und selbst eingetragener Lehrer als Liste
# ===========================================================================
sub make_hash_lehrer_in_klassen {
   # key: klasse Value=Liste unterrichtender Lehrer
   %lehrer_in_klassen=&get_klassen_in_schule_hash();

   # Hash mit leerer Liste füllen (sonst tuts nicht)
   while (($key,$value) = each %lehrer_in_klassen){
      $lehrer_in_klassen{$key} = [""];
   }

   my @lehrerliste=&get_lehrer_in_schule();
   #   print "@lehrerliste";

   my $lehrer="";

   foreach $lehrer (@lehrerliste) {
   if($Conf::log_level>=3){
      print "### Suche bei: $lehrer\n";
   }
   if (-e "/home/lehrer/$lehrer/.sophomorix/_Meine-Klassen") {
      open(DOTFILE,"/home/lehrer/$lehrer/.sophomorix/_Meine-Klassen") || die "Fehler: $!";
         while(<DOTFILE>){
            chomp();
           s/\s//g; # Whitespace Entfernen
            if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
            if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
            #print "$_\n";

            if($Conf::log_level>=3){
               print "   Lehrer $lehrer ist in Klasse $_\n";
            }
            # Lehrerlogin an die vorhandene Liste im Hash anhängen
            push(@{ $lehrer_in_klassen{"$_"} }, $lehrer);
         }

      close(DOTFILE);
    }
 }
   if($Conf::log_level>=3){
      # Login-Typ ausgeben
      &titel("Gebe Klassen aus und Lehrer, die Darin unterrichten.");
      while (($key,$value) = each %lehrer_in_klassen){
        printf "%-10s %3s\n","$key","@{ $lehrer_in_klassen{$key}  }";
      }
   }

}


sub get_lehrer_in_klasse {
 # wenn kein lehrer in dieser Klasse ist, 
 # oder die Klasse nicht im Hash vorkommt,
 # dann leere Liste zurück
 my ($klasse) = @_;
 my @liste=();
 # hole die liste aus dem Hash
 if (exists ($lehrer_in_klassen{$klasse})) {
   @liste=@{$lehrer_in_klassen{$klasse}}; 
 } else { 
   # leere liste zurück
   @liste=("");
 }
 return @liste; 
}


# ===========================================================================
# 2. Link zu public_html erzeugen
# ===========================================================================
#sub add_public_html_link {
#    # 2. Link zum public_html der User anlegen
#    my ($login,$group) = @_;
#    &do_falls_nicht_testen(
#       "ln -s $DevelConf::apache_root/userdata/$group/$login/public_html $DevelConf::apache_root/users#/$login"
#    );
#}

#sub remove_public_html_link {
#    # 2. Link zum public_html der User entfernen
#    my ($login,$group) = @_;
#    &do_falls_nicht_testen(
#       "rm $DevelConf::apache_root/users/$login"
#    );
#}




################################################################################
# WEBMIN
################################################################################


sub get_raum_buchung {
   my $lock_data="$DevelConf::dyn_config_pfad/lock_data";
   my %raum_buchung=();
   my $raum="";
   my $lehrer="";
   my $string="";
   my $lock_datum="";
   if (not -e "$lock_data") {
     return %raum_buchung; 
   } else {
     open(LOCKDATA, "$lock_data");
     while(<LOCKDATA>){
      # Führt zu Fehlern, da vor Header 
      #print "$_";
        chomp();
       ($raum, $lehrer, $lock_datum) = split(/::/);
        $string="$lehrer"."::"."$lock_datum";
        $raum_buchung{$raum}="$string";
     #print "Raum $raum und Lehrer $lehrer<br>\n";
     }
     close(LOCKDATA);
     return %raum_buchung; 
   }
}

# ===========================================================================
# Pfade ermitteln zur Konfigurationsdatei  (NUR WEBMIN) 
# ===========================================================================
# Diese Fuktion setzt den Pfad zur Konfiguratuionsdatei für den gerade angemeldeten user
# Falls die Konfigurationsdatei nicht vorhanden ist, wird sie als leere Datei angelegt
sub get_config_datei_meine_klassen {
     $loginname="$ENV{'REMOTE_USER'}";
     # Falls lehrerlogin übergeben, DESSEN Meine-Klassen suchen
     ($parameter)=@_;
     if ($parameter ne "") {
        $loginname=$parameter;
     }
     # print "$loginname<p>";
     # Pfad zur Konfigurationsdatei bestimmen
     if ($loginname eq "" || not defined $loginname) {
         print "Loginname konnte nicht ermittelt werden";
     } elsif ($loginname eq "admin") {
         $config_pfad="/home/admin/.sophomorix";
     } else {
         $config_pfad="/home/lehrer/${loginname}/.sophomorix";
     }
     $config_datei="${config_pfad}"."/_Meine-Klassen";

     # Anlegen, falls nicht vorhanden
     if (! -e $config_pfad){
           system("mkdir $config_pfad");
     }

     if (! -e $config_datei){
           system("touch $config_datei");
     }

     # lehrer soll Datei nicht ändern dürfen
     system("chown -R root:root $config_pfad");
     #print "$config_datei<p>";
     return $config_datei;
}







# ===========================================================================
# Diese Fuktion ermittelt den Link-Pfad (NUR WEBMIN)
# ===========================================================================
# Falls der Link-Pfad nicht vorhanden ist, wird er angelegt
sub get_link_pfad {
     my $link_pfad="";
     $loginname="$ENV{'REMOTE_USER'}";
     # Pfad zur Konfigurationsdatei bestimmen
     if ($loginname eq "" || not defined $loginname) {
         print "Loginname konnte nicht ermittelt werden";
     } elsif ($loginname eq "admin") {
         $link_pfad="/home/admin/windows/_Meine-Klassen";
     } else {
         $link_pfad="/home/lehrer/${loginname}/windows/_Meine-Klassen";
     }

     # Anlegen, falls nicht vorhanden
     if (! -e $link_pfad){
           system("mkdir $link_pfad");
     }

     # lehrer soll Verzeichnis nicht ändern dürfen (tut nicht)
     system("chown root:root $link_pfad");
     # auskommentieren zum testen
     #print "$link_pfad<p>";
     # Linux-Seite: Link auf Windows-Linkverzeichnis
     my $string;
     $string="/home/lehrer/${loginname}/_Meine-Klassen";
     #print "$string";
     if (! -e $string){
        system("ln -s ${link_pfad} $string");
     }
     return $link_pfad;
}



# ===========================================================================
# Löschen von Schüler-Dateien
# ===========================================================================
sub daten_loeschen_schueler {
   # Hash der Schüler_ids erzeugen
   # loginnamen aller Schüler
   my @user_loesch_liste=&get_schueler_in_schule();
   my %user_loesch_hash_id=();
   # Liste/Hash mit id's füllen
   foreach $user (@user_loesch_liste) {
      my $uid=getpwnam $user;
      # erzeugt Liste  
      #push(@user_loesch_liste_id, $uid);
      # erzeugt Hash
      $user_loesch_hash_id{$uid}="";
   }
   # Ausgabe des Hashes
   #   while (($k) = each %user_loesch_hash_id){
   #      print "Lösche $k<p>";
   #   }
   # Lösch-Funktion aufrufen, Parameter ist Hash mit user-id's
   &daten_loeschen(%user_loesch_hash_id);
}



# ===========================================================================
# Löschen von Eigenen Lehrer-Dateien
# ===========================================================================
sub daten_loeschen_ich_lehrer {
   my $loginname="$ENV{'REMOTE_USER'}";
   my %user_loesch_hash_id=();
   my $loginname_id=getpwnam $loginname;
   # erzeugt Hash mit nur dem einen Lehrer, der eingeloggt ist
   $user_loesch_hash_id{$loginname_id}="";
   # Lösch-Funktion aufrufen, Parameter ist Hash mit user-id's
   &daten_loeschen(%user_loesch_hash_id);
}




# ===========================================================================
# Löschen von Lehrer-Dateien
# ===========================================================================
sub daten_loeschen_lehrer {
   # Hash der Lehrer_ids erzeugen
   # loginnamen aller Lehrer
   my @user_loesch_liste=&get_lehrer_in_schule();
   my %user_loesch_hash_id=();
   # Liste/Hash mit id's füllen
   foreach $user (@user_loesch_liste) {
      my $uid=getpwnam $user;
      # erzeugt Liste  
      #push(@user_loesch_liste_id, $uid);
      # erzeugt Hash
      $user_loesch_hash_id{$uid}="";
   }
   # Ausgabe des Hashes
   #   while (($k) = each %user_loesch_hash_id){
   #      print "Lösche $k<p>";
   #   }
   # Lösch-Funktion aufrufen, Parameter ist Hash mit user-id's
   &daten_loeschen(%user_loesch_hash_id);
}






# ===========================================================================
# Löschen vo Dateien von Usern im übergebenen Hash
# ===========================================================================
# Löscht alle Daten, die Usern aus dem übergebenen Hash gehören
sub daten_loeschen {
   my %user_loesch_hash_id = @_;
   # Verarbeitung
   # Infos zur Datei holen (lstat: gibt links statt deren Quelle zurück)
   my @statliste=lstat($File::Find::name);
   my $owner= getpwuid $statliste[4];
   my $deletestring="$File::Find::name";
   # nur zum testen ob löschen verhindert wird.
   #$deletestring="/home/tausch/klassen/km1kb2t"; 
   if (exists $user_loesch_hash_id{$statliste[4]}) {
      # Nochmal checken, ob wirklich löschen
      if ($deletestring=~/^\/home\/tausch\/klassen\/${klasse}\//) {
         print "<b>Lösche : ","$deletestring"," ---> Eigentümer: $statliste[4]","($owner)","</b><p>";
         #rmtree($deletestring); 
         # tut, aber gefährlich und löscht root-Dateien in Unterverzeichnissen
         # alternative:
         # + nicht so gefährlich
         # + root-Dateien bleiben erhalten
         # +- Verzeichnisse von schuelern/lehrern bleiben erhalten, wenn eine root-Datei drin ist
         unlink($deletestring); # falls es eine Datei ist
         rmdir($deletestring);  # falls es ein Verzeichnis ist
      }
   } else {
     print "Nicht gelöscht: ","$deletestring"," ---> Eigentümer: $statliste[4]","($owner)","<p>";
   }
}



# Eine Liste des Verzeichnisinhalts erstellen
sub get_dir_list {
  my ($path)=@_;
  my @filelist=();
  my $abs_path="";
  my $leer=1;
  #my $dir="0";
  if (not -e $path) {
    return "-1";
  } else {
     opendir VERZ, $path or die "kann $path nicht öffnen";
     foreach my $datei (readdir VERZ){
         if ($datei eq "."){next};
         if ($datei eq ".."){next};
         $leer=0;
         $abs_path = "$path"."/"."$datei";
         if (-d "$abs_path") {
          $datei="$datei"."/";
	} elsif (-l "$abs_path") {
          $datei = "$datei"." (link)";
	}
         push (@filelist, $datei);
     }
     if ($leer==1) {
        return "0";
     } else {
        @filelist = sort @filelist;
        # als erstes element 1 Zurcück = mit Inhalt
        unshift (@filelist, "1");
        return @filelist;
     }
  }
}




# Eine Liste als td ausgeben (tabledata)
# Erstes Element der Rückgabeliste gibt an:
#  -1: Verzeichnis existiert nicht
#   0: Verzeichnis ist leer (nur . und .. sind da)
#   1: Verzeichnis enthält Daten
sub td_ausgeben {
  my ($error, @liste) = @_;
  my $item="";
  
  if ($error eq "-1") {
     print "  <td bgcolor=#FF3300><b>";
     print "Verzeichnis existiert nicht<br>";
   } elsif ($error eq "0") {
        print "  <td bgcolor=#FF9966><b>";
     print "Verzeichnis ist leer<br>";
   } else {
        print "  <td bgcolor=#66FF99><b>";
	foreach $item (@liste){
	  if ($item=~/\//) {
           # Verzeichnissymbol
           print "<img src=\"/images/dir.gif\">";
	 } else {
           # Dateisymbol 
           print "<img src=\"/images/text.gif\">";
         }
           print " $item <br>";
	}
   }
   print "</b></td>\n";
}


# Eine Liste ausgeben in einer Tabelle (ohne Rand)
# Erstes Element der Rückgabeliste gibt an:
#  -1: Verzeichnis existiert nicht
#   0: Verzeichnis ist leer (nur . und .. sind da)
#   1: Verzeichnis enthält Daten
sub liste_ausgeben {
  my $spalten_anzahl=2;
  my ($error, @items) = @_;

  if ($error eq "-1") {
     print "<br><font color=red><b>Verzeichnis existiert nicht</b></font><p>";
   } elsif ($error eq "0") {
     print "<br><font color=red><b>Das Verzeichnis ist leer</b></font><p>";
   } else {
	foreach $item (@liste){
           print "$item <br>";
	}
   }

   # Auffüllen mit leeren Feldern
   while ( ($#items+1) % $spalten_anzahl !=0) {
     push (@items, "&nbsp;");
   }
   # Ausgeben als Tabelle
   print "<table border=0 bgcolor=lightgrey cellpadding=5 width=100% border>\n";
   while ( ($#items+1) != 0) {
      print "<tr>\n";
      my $item="";
      for ($i = 1; $i <= $spalten_anzahl; $i++) {
         $item = shift(@items);
         print "  <td width=25%><b>$item</b></td>\n";
      }
      print "</tr>\n";
   }
   print "</table>\n";
}


################################################################################
# MAIL
################################################################################

# ===========================================================================
# Mail-alias aus /etc/mail/aliases ermitteln
# ===========================================================================
#
sub get_mail_alias_from {
   my ($username, $param) = @_;
   if (not defined $param) {
       $param="";
   }

   my $begin_automatisch=0;
   my @liste=();
   if ($param eq "liste") {
      # jede Zeile durchsuchen, auch manuell konfigurierte
      $begin_automatisch=1;
   }

   open(ALIASES, "</etc/mail/aliases");
      while (<ALIASES>) {
          # Erste ab dieser Zeile beginnen
          if(/^\# Automatisch erzeugt:/){$begin_automatisch=1}

          if ($begin_automatisch==1) {
             # wenn die Automatischen Einträge erreicht sind
             s/\s//g; # Spezialzeichen raus
             if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
             if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
             if(not /:/){next;} # Bei fehlendem Doppelpunkt aussteigen

             # gültige Zeilen untersuchen
             my($alias, $login)=split(/:/);

             if (not defined $username) {
               # ungültige Zeile/Listenzeile/kein Parameter übergeben
                return "";
                close(ALIASES);
                exit;
             }

             if ($login eq $username) {
                #print "$alias";
	       if ($param eq "liste") {
                   push @liste, $alias;     
	       } else {
                   return $alias;
                   close(ALIASES);
                   exit; 
	      }
             }
          }

      }

   close(ALIASES);
   if ($param eq "liste") {
      return @liste;
    } else {
      # wenn nichts gefunden, dann username zurückgeben
      return $username;
    }


}




################################################################################
# QUOTA
################################################################################
sub checked_quotastring {
   # input 1: string, der in Quotaangaben stehen kann:
   # Bsp.     156      1332+132  x-12-x-x+23
   # input 2: Dateiname für Fehlermeldung
   # input 3: Zeile, oder ähnliches, um Fehler zu finden
   my ($quota_string, $datei, $zeile)=@_;
   my @quota_liste=();
   my @quota_filesystems=&get_quota_fs_liste();
   my $quota_fs_anzahl=$#quota_filesystems+1;

   # aufsplitten am plus 
   @quota_liste=split(/\+/, $quota_string);

         if ($#quota_filesystems!=$#quota_liste){
             print "\n#########################################################\n",
                   "########## Abbruch: $datei nicht korrekt: ##########\n",
                   "#########################################################\n\n",
                   " Zeile: $zeile\n\n",
                   "Es müssen bei ALLEN Usern für $quota_fs_anzahl Dateisystem(e)",
                   " Quotaangaben gemacht werden.\n\n";
             if ($datei ne "quota.txt") {
             print "(in schulinfo.txt oder lehrer.txt kann auch das Wort 'quota' stehen).\n\n";
	   }
             exit; # Abbruch
         }

   foreach $quotawert (@quota_liste) {
      # Minux-Anzahl prüfen
      my $minus_anzahl=$quotawert=~tr/-//;
      if ($minus_anzahl == 3) {
          # Angabe mit 3 -
          my @qwert_liste=split(/-/, $quotawert);
          if ((not $qwert_liste[0]=~/[^0-9]/ or $qwert_liste[0] eq "x")
           and (not $qwert_liste[1]=~/[^0-9]/)
           and (not $qwert_liste[2]=~/[^0-9]/ or $qwert_liste[2] eq "x")
           and (not $qwert_liste[3]=~/[^0-9]/ or $qwert_liste[3] eq "x")
           ){
             # Alles OK
          } else {
             print "\n#########################################################\n",
                   "########## Abbruch: $datei nicht korrekt: ##########\n",
                   "#########################################################\n\n";
             print " $quotawert ist Fehlerhaft\n\n";
             print " Zeile: $zeile\n\n";
             exit;
          }

      } elsif ($minus_anzahl == 0){
          # Angabe ohne -

      } else {
        # Weder 0 noch 3 Minusse
        print "Fehler: Es müssen keine oder 3 Minusse in $quota_string vorhanden sein!\n";
        exit;
      }
  

 }
   
   #print "String: $quota_string Liste: @quota_liste\n";
   return @quota_liste;
}


# ===========================================================================
# Quota setzten
# ===========================================================================
   # $userkey:                             username
   # \@quota_filesystems                   Referenz auf Liste mit filesystemen
   # \@{ $login_quota_hash{$userkey} }     Referenz auf den Key $userkey im 
   # Hash %login_quota_hash, der eine Referenz auf die Liste mit den Quota enthält   
   # Beispiel: &setze_quota($userkey , \@quota_filesystems, \@{ $login_quota_hash{$userkey} } );
sub setze_quota {
   # neue, private Variablen für diesen Block anlegen
   my $quotastring="";
   my $minus_anzahl=0;
   # Optionen für den setquota-Befehl
   my $q_opt1="";
   my $q_opt2="";
   my $q_opt3="";
   my $q_opt4="";
   my $fs; 
   my $j=0;
   my $uid=-1;
   # Parameter 
   # $user:                 username
   # $fsliste               Referenz auf Liste mit Filesystemen (für alle user gleich)
   # $quotastring           Referenz auf Liste mit Quota (für übergebenen user)
   my ($user,$fsliste, $quotaliste)=@_;
   # Nun die Elemente der Dateisystem-Liste durchgehen von 1 bis j
   for ($j=0; $j < @$fsliste; $j++){
   
      # sagen, was ich mache 
      if($Conf::log_level>=3){
         print ("Setze Quota:\n");
         #print ("Setze Quota ","$fsliste->[$j]", " auf ","$quotaliste->[$j]","\n");
      }
      # Aus der Listenreferenz das j-te Element herausnehmen
      $quotastring = $quotaliste->[$j];
      $fs = $fsliste->[$j];

      # Leerzeichen aus quotastring entfernen und return abschneiden
      chomp($quotastring);
      $quotastring=~s/ //g;
   
      # falls Minus-Zeichen vorhanden, aufsplitten
      if ($quotastring=~/-/) {
         # quotastring aufsplitten
         ($q_opt1,$q_opt2,$q_opt3,$q_opt4)=split(/-/,$quotastring);
      } else {
         # sonst ist nur Ziffer vorhanden, also Werte setzen
         $q_opt1="x";
         $q_opt2=$quotastring;
         $q_opt3="x";
         $q_opt4="x";
      }
      # Prüfen, ob x angegeben ist
      # x im ersten Parameter
      if ($q_opt1 eq "x"){
        # Softlimit ca. 20% unter Hardlimit
        $q_opt1=$q_opt2-int($q_opt2/5);
      }
      # x im zweiten Parameter
      if ($q_opt2 eq "x"){
        # Fehler und Abbruch
        print ("\n\nHardlimit darf nicht mit x angegeben werden!\n\n");
        die;
      }
      # x im dritten Parameter
      if ($q_opt3 eq "x"){
        # 80% des Hardlimits
        $q_opt3=80*$q_opt2;
      }
      # x im vierten Parameter
      if ($q_opt4 eq "x"){
        # Wenn Dateien durchschnittlich unter 10kB/Datei gibts Probleme
        $q_opt4=100*$q_opt2;
      }

      # Quotabefehl als string erzeugen (abhängig von Kernelupdate)
      if ($DevelConf::kernel_update eq "ja") {
         #print ("kernel 2.4\n");
         # ML-Kernelupdate auf 2.4.18
         $quota_befehl="setquota -u ${user} ${q_opt1}000 ${q_opt2}000 ${q_opt3} ${q_opt4} ${fs}";

      } else {
         # print ("kernel 2.2\n");
         # ML-Kernel 2.2.16
         $quota_befehl="setquota -u ${user} ${fs} ${q_opt1}000 ${q_opt2}000 ${q_opt3} ${q_opt4}";
      }

      # Quota-Befehle an der Konsole ausgeben
	if (not $DevelConf::system==1){
           # Quota-Modul benutzen
           # user-ID ermitteln
           ($a,$a,$uid)=getpwnam("$user");
	   if (not defined $uid) {
              $uid=999999;
              print("UserID:            n.A., da Testlauf (UID=$uid, show must go on.)\n");
           }
           if($Conf::log_level>=3){
              # Ausgeben der ermittelten werte
              print("Device:            ${fs}\n");
              print("User:              ${user}\n");
              print("UserID:            $uid\n");
              print("Block-Softlimit:   ${q_opt1}000  \n");
              print("Block-Hardlimit:   ${q_opt2}000  \n");
              print("Inode-Softlimit:   ${q_opt3}     \n");
              print("Inode-Hardlimit:   ${q_opt4}     \n");
	 }
	} else {

           print("${quota_befehl}","\n");
         
        }

      # Mit setquota die Quota der user tatsächlich anpassen

      if(not $DevelConf::testen==1) {
        #Es ist ernst
	if (not $DevelConf::system==1){
          # Quota-Modul benutzen
          Quota::setqlim($fs,$uid,"${q_opt1}000","${q_opt2}000",$q_opt3,$q_opt4);
          print "Setze Quota auf $fs für User $uid \n"; 
          print "auf: ${q_opt1}000 ${q_opt2}000 $q_opt3 $q_opt4 \n";
	} else {
          # Systembefehl benutzten
          system("${quota_befehl}")
        } 

      } else {
          print "Test: Setze Quota auf $fs für User $uid \n"; 
          print "auf: ${q_opt1}000 ${q_opt2}000 $q_opt3 $q_opt4 \n";
      }
   # Quota aufsummieren
   $DevelConf::q_summe[$j]=$DevelConf::q_summe[$j]+$q_opt2;
   }
}



# ===========================================================================
# Hash mit standard_quota ermitteln
# ===========================================================================
sub get_standard_quota {
   my %standard_quota_hash=();
   my @soll_quota_liste=();
   my @quota_filesystems=&get_quota_fs_liste();   

   my $user="";
   my $soll_quota=0;
   open(QUOTASOLL,"${DevelConf::config_pfad}/quota.txt") || die "Fehler: $!";
   while(<QUOTASOLL>){
      chomp();
      s/\s//g; # Whitespace Entfernen
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      # user von sollquota splitten
      ($user,$soll_quota)=split(/:/);
      @soll_quota_liste = &checked_quotastring($soll_quota, "quota.txt", $_);
      # Zum Login-Quota-Hash dazunehmen
      $standard_quota_hash{$user}=[@soll_quota_liste];
   }
   close(QUOTASOLL);

   # Für jeden User in quota.txt die Quota auf allen Filesystemen ausgeben
   if($Conf::log_level>=3){
      &titel("Extrahierte Werte aus quota.txt :");
      for my $users ( keys %standard_quota_hash ) {
         printf "%-40s %8s MB\n","$users (Sollwert)","@{ $standard_quota_hash{$users} }";
       }
      print "\n";
   }
   # Rückgabe-Hash enthält standard-quota UND Einzel-Quota
   return %standard_quota_hash;
}



# ===========================================================================
# Hash mit lehrer_quota ermitteln
# ===========================================================================
sub get_lehrer_quota {
   my @quota_filesystems=&get_quota_fs_liste(); 
   my %lehrer_quota_hash=();
   my @lehrer_quota_liste=();
   my ($gruppe,
       $nachname,
       $vorname,
       $datum,
       $login_lehrer,
       $passwort,
       $kuerzel,
       $lehrer_quota,
       $email_sender,
       $email_alias)=();

   open(LEHRER,"${DevelConf::users_pfad}/lehrer.txt") || die "Fehler: $!";
   while(<LEHRER>){
      chomp();
      s/\s//g; # Whitespace Entfernen
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($gruppe,
       $nachname,
       $vorname,
       $datum,
       $login_lehrer,
       $passwort,
       $kuerzel,
       $lehrer_quota,
       $email_sender,
       $email_alias)=split(/;/);
       # Wenn Quotaangabe vorhanden, dann benutzen
       if($lehrer_quota ne "quota"){
         @lehrer_quota_liste = &checked_quotastring($lehrer_quota, "lehrer.txt", $_);
         $lehrer_quota_hash{$login_lehrer}=[@lehrer_quota_liste];
      }
   }
   close(LEHRER);

   # Für Lehrer mit Sonderquota die Quota auf allen Filesystemen ausgeben
   if($Conf::log_level>=3){
      &titel("Extrahierte Werte aus lehrer.txt :");
      for my $users ( keys %lehrer_quota_hash ) {
         printf "%-40s %8s MB\n","$users (Sollwert)","@{ $lehrer_quota_hash{$users} }";
       }
      print "\n";
   }
   # Rückgabe-Hash enthält key=lehrer-login, value=quotaliste 
   return %lehrer_quota_hash;
}





# ===========================================================================
# Hash mit klassen_quota ermitteln
# ===========================================================================
sub get_klassen_quota {
   my @quota_filesystems=&get_quota_fs_liste(); 
   my %klassen_quota_hash=();
   my @klassen_quota_liste=();
   my ($klasse,
       $abteilung,
       $typ,
       $mail,
       $klassen_quota)=();
   open(SCHULINFO,"${DevelConf::users_pfad}/schulinfo.txt") || die "Fehler: $!";
   while(<SCHULINFO>){
      chomp();
      s/\s//g; # Whitespace Entfernen
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      if(/^\#/){next;} # Bei Kommentarzeichen aussteigen
      ($klasse,
       $abteilung,
       $typ,
       $mail,
       $klassen_quota)=split(/;/);
       # gid der Klasse ermitteln
       # k vor Klasse setzten  
       $klasse="k"."$klasse";
       # Wenn Quotaangabe vorhanden, dann benutzen
       if($klassen_quota ne "quota"){
         @klassen_quota_liste = &checked_quotastring($klassen_quota, "schulinfo.txt", $_);
         $klassen_quota_hash{$klasse}=[@klassen_quota_liste];
       }
   }
   close(SCHULINFO);

   # Für Klassen mit Sonderquota die Quota auf allen Filesystemen ausgeben
   if($Conf::log_level>=3){
      &titel("Extrahierte Werte aus schulinfo.txt :");
      for my $klassen ( keys %klassen_quota_hash ) {
         printf "%-40s %8s MB\n","$klassen (Sollwert)","@{ $klassen_quota_hash{$klassen} }";
       }
      print "\n";
   }
   # Rückgabe-Hash enthält key=lehrer-login, value=quotaliste 
   return %klassen_quota_hash;
}




#   # Rückgabe-Hash enthält key=klassen-name, value=quotaliste 
#   return %standard_quota_hash;

# ===========================================================================
# Quotierte Dateisysteme ermitteln
# ===========================================================================
# Ermittle aus /etc/mtab die momentan benutzten Quota-Dateisysteme 
# (z.B /dev/hda4) und deren Mountpoint
# Dazu ist das Quota-Modul erforderlich
sub get_quota_fs_liste {
   my @quota_fs=();

   Quota::setmntent();
   while (($dev, $path, $type, $opts) = Quota::getmntent()) {
      #print"$dev $path $type $opts<p>";
      if ($opts=~/usrquota/){
       #print"$dev $path $type $opts hinzugenommen<p>";
       push(@quota_fs, $dev)
      }

   }
   Quota::endmntent();

   #print "Quota-Filesysteme(Liste):  @quota_fs";

   return @quota_fs;
}




################################################################################
# PASSWORT-TOOLS
################################################################################
sub sophomorix_passwd {
   my ($user,$passwd) = @_;
   if ($DevelConf::testen==0) {
      # kein Test
      if($Conf::log_level>=3){
         print "sophomorix_passwd:  Setze Passwort von $user auf $passwd\n";
      } 
      # pw verschluesseln
      open(PASSWD,"| /usr/sbin/chpasswd");
        print PASSWD "$user:$passwd\n";
      close(PASSWD);
      # smbpasswd:  -s = silent, (-a entfernt, da user schon da)
      open(SMBPASSWD,"| /usr/bin/smbpasswd -s $user");
        # Passwort in smbpasswd setzen
        print SMBPASSWD "$passwd\n$passwd\n"; 
      close(SMBPASSWD);
    } else {
       if($Conf::log_level>=3){
          print "(Test) sophomorix_passwd:  Setze Passwort von $user auf $passwd\n";
       } 
    }
}




sub get_erst_passwd {
  my ($username) = @_;
  my $rainer=0; # Hilfsvariable
  open(PASSPROT, "$DevelConf::dyn_config_pfad/user.protokoll");
  while(<PASSPROT>) {
      chomp(); # Returnzeichen abschneiden
      s/\s//g; # Spezialzeichen raus
      if ($_ eq ""){next;} # Wenn Zeile Leer, dann aussteigen
      my ($gruppe, $nax, $login, $pass) = split(/;/);
      if ($username eq $login) {
          $rainer=1;
          if ($gruppe eq "lehrer" or $gruppe eq "speicher") {
              #print "Fehler: $login ist ein Lehrer";
              #return-STRING NICHT AENDERN !!! (wegen klassenmanager/passwd_change.cgi)
              return "$login ist ein Lehrer";
          } else {
             print "$login $pass";
             return $pass;
          }
      } 

  }
  close(PASSPROT);
  # # return-STRING NICHT AENDERN !!! (wegen klassenmanager/passwd_change.cgi)
  if ($rainer==0){return "Passwort konnte nicht ermittelt werden!"} 
}

################################################################################
# FIREWALL-TOOLS
################################################################################
sub check_internet_status {
   my ($raum) = @_;
   my $status=0;
   # 0: off
   # sonst on
   $status = system("ipchains -L $raum >/dev/null 2>&1");
   return $status;
}


################################################################################
# Austeilen-Einsammeln
################################################################################
sub austeilen_manager{
  # Parameter 1: Aus welchem Verzeichnis wird ausgeteilt
  # Parameter 2: In welche gruppe wird ausgeteilt 
  # Parameter 3: Modus(ka, kachange, unt, untchange) 
  my ($loginname, $gruppe, $aendern_modus) = @_;
  my $aufgaben="/home/lehrer/${loginname}/windows/aufgaben";

  # Ziel beim austeilen(Rechts) 
  # bei KA
  my $tausch_ka="/home/klassenarbeit/${gruppe}/aufgaben/${loginname}";
  # bei Unterricht
  #my $tausch_unt="/home/tausch/klassen/${gruppe}/${loginname}";
  my $tausch_unt="/home/aufgaben/${gruppe}/${loginname}";


  # Quelle beim austeilen (ka UND unterricht)
  my $aufgaben_grp="/home/lehrer/${loginname}/windows/aufgaben/${gruppe}";

  if (not -e $aufgaben) {
  setup_verzeichnis("/home/lehrer/\$lehrer/windows/aufgaben",
                    "$aufgaben","$loginname");
  }

  &check_verzeichnis_mkdir("$aufgaben_grp");
  system ("chown $loginname.lehrer $aufgaben_grp");
  &check_verzeichnis_mkdir("$tausch_ka");
#  system ("chown $loginname.lehrer $aufgaben_grp");

  print "<table width=100% border>\n";
  print "<tr $tb>\n";
  print "  <td width=35%><b>Inhalt des Verzeichnisses </b><p>\n";
#  if ($aendern_modus eq "ka" || $aendern_modus eq "kachange" ) {
#     print "                <b><tt>H:\\aufgaben\\${gruppe}</tt> </b><p>\n";
#  } else {
     print "                <b><tt>H:\\aufgaben\\${gruppe}</tt> </b><p>\n";
#  }
  print "                <b>des austeilenden Lehrers <tt>$loginname</tt></b>";
  print "  </td>\n";
  print "  <td align=middle width=30%><b>Aktion</b></td>\n";
#  if ($aendern_modus eq "ka" || $aendern_modus eq "kachange" ) {
#     print "  <td width=35%><b>Inhalt des Netzlaufwerks<p></b>\n";
#     print "                <b><tt>V:\\$loginname</tt><p></b>\n";
#     print "                <b>aller Computer in Raum <tt>$gruppe</tt></b>\n";
#  } else {
     print "  <td width=35%><b>Inhalt des Netzlaufwerks<p></b>\n";
     print "                <b><tt>V:\\$loginname</tt><p></b>\n";
     print "                <b>aller Schüler der Klasse <tt>$gruppe</tt></b>\n";
#  }
  print "  </td>\n";
  print "</tr>\n";

  print "<tr>";

#  if ($aendern_modus eq "ka" || $aendern_modus eq "kachange" ) {
#    my @ls_out=&get_dir_list($aufgaben_ka);
#    &td_ausgeben(@ls_out);
#  } else {
    my @ls_out=&get_dir_list($aufgaben_grp);
    &td_ausgeben(@ls_out);
#  }

# Mittlere Spalte
  print "  <td align=middle width=15%><b>";
   if ($aendern_modus eq "kachange" || $aendern_modus eq "untchange" ) {
      # ändern 
      #print " <img alt=\"->\" src=\"/images/right.gif\">\n";
      print " <img alt=\"=\" src=\"images/equal.gif\"><br>\n";
      print "      <input type=radio name=sync value=yes> synchronisieren (abgleichen)<p>\n";

      print " <img alt=\"->\" src=\"/images/right.gif\">";
      print " <img alt=\"->\" src=\"/images/right.gif\"><br>\n";
      print "      <input type=radio name=sync value=add> zusätzlich austeilen<p><br>\n";

      print "      <input type=radio name=sync value=no checked> Nichts ändern<p>\n";
   } else {
      # Neu-Modus:
      #print " <img alt=\"->\" src=\"/images/right.gif\">\n";
      print " <img alt=\"=\" src=\"images/equal.gif\"><br>\n";
      print "      <input type=radio name=sync value=yes checked> synchronisieren (abgleichen)<p>\n";

      print " <img alt=\"->\" src=\"/images/right.gif\">";
      print " <img alt=\"->\" src=\"/images/right.gif\"><br>\n";
      print "      <input type=radio name=sync value=add> zusätzlich austeilen<p><br>\n";

      print "      <input type=radio name=sync value=no> Dateien NICHT austeilen<p>\n";
   }
  print "</b></td>\n";

  
  # Rechte Spalte
#  my @tausch=&get_dir_list($tausch);
#  &td_ausgeben(@tausch);

  if ($aendern_modus eq "ka" || $aendern_modus eq "kachange" ) {
    my @ls_out=&get_dir_list($tausch_ka);
     &td_ausgeben(@ls_out);
  } else {
    my @ls_out=&get_dir_list($tausch_unt);
    &td_ausgeben(@ls_out);
  }


  print "</tr>\n";

  print "</table>\n\n";

print "<p>";

}




sub ka_austeilen {
  # Praumarameter 1: Wer Teilt aus
  # Parameter 2: In welchen Raum wird ausgeteilt
  # Parameter 3: delete oder undelete bei rsync
  my ($loginname, $raum, $type) = @_;
  my $lehrer_pfad ="/home/lehrer/${loginname}/windows/aufgaben/$raum/";
  my $raum_pfad = "/home/klassenarbeit/${raum}/aufgaben/${loginname}";
  #print "Teile aus von $lehrer_pfad nach $raum_pfad<p>";
  # -t Datum belassen
  # -n Nur so tun, als ob
  # -r Rekursiv
  # -o Owner beibehalten
  if ($type eq "delete") {
    system("rsync -tor --delete $lehrer_pfad $raum_pfad");
  } else {
    system("rsync -tor $lehrer_pfad $raum_pfad");
  }
}


sub unterricht_austeilen {
  # Praumarameter 1: Wer Teilt aus
  # Parameter 2: In welche Klasse wird ausgeteilt
  # Parameter 3: delete oder undelete bei rsync
  my ($loginname, $klasse, $type) = @_;
  my $lehrer_pfad ="/home/lehrer/${loginname}/windows/aufgaben/${klasse}/";
  # Achung: share aufgabe (ohne n) ist in /home/aufgaben
  my $klasse_pfad = "/home/aufgaben/${klasse}/${loginname}/";
#  my $klasse_pfad = "/home/tausch/klassen/${klasse}/${loginname}/";
  #print "Teile aus von $lehrer_pfad nach $klasse_pfad<p>";
  # -t Datum belassen
  # -n Nur so tun, als ob
  # -r Rekursiv
  # -o Owner beibehalten
  if ($type eq "delete") {
    system("rsync -tor --delete $lehrer_pfad $klasse_pfad");
  } else {
    system("rsync -tor $lehrer_pfad $klasse_pfad");
  }
}



sub ka_einsammeln {
  # Parameter 1: Wer sammelt ein
  # Parameter 2: In welchem Raum  wird eingesammelt 
  my ($loginname, $raum) = @_;
  my $lehrer_login="";
  my $date="no_time";
  # Dateinamen ermitteln
  # Datum
  my %raum_buchung=&get_raum_buchung();

  if (exists ($raum_buchung{$raum})) {
     ($lehrer_login,$date) = split(/::/,$raum_buchung{$raum} );
     print "<b>Raum: $raum</b><br>";
     print "<b>Lehrer: $lehrer_login</b><br>";
     print "<b>Datum: $date</b><br>";
     print "<p>";

  } else {
     print "<b>Raum ist nicht für $loginname gesperrt!</b><p>";
     exit; 
  }

  my $sammelordner="";
  my $lehrer_pfad ="";
  my $lehrer_verzeichnis="/home/lehrer/${loginname}/windows/sammelordner/KA-${raum}_${date}";
  my $log_verzeichnis="${DevelConf::log_pfad_ka}/KA-${raum}_${date}_${loginname}";
  my $aufgaben="/home/klassenarbeit/${raum}/aufgaben/${loginname}";
  my $user="";
  my @raum = &get_workstations_in_raum($raum);
  &check_verzeichnis_mkdir("${log_pfad_ka}");
  # Verzeichnis Anlegen
  
  # repair.directories einlesen
  &get_alle_verzeichnis_rechte();
  # Sicherstellen, dass der sammelordner beim Lehrer existiert
  &setup_verzeichnis("/home/lehrer/\$lehrer/windows/sammelordner",
                       "/home/lehrer/$loginname/windows/sammelordner",
                     "$loginname");
  &check_verzeichnis_mkdir("${lehrer_verzeichnis}");
  &check_verzeichnis_mkdir("${DevelConf::log_pfad_ka}");
  &check_verzeichnis_mkdir("${log_verzeichnis}");
 

  foreach $ws (@raum) {
      print "<b> Sammle $ws ein ...</b>";
      $lehrer_pfad ="$lehrer_verzeichnis/${ws}";
      $log_pfad_ka="$log_verzeichnis/${ws}";
 
      &check_verzeichnis_mkdir("${lehrer_pfad}");
      &check_verzeichnis_mkdir("${log_pfad_ka}");

      $sammelordner = "/home/workstations/${raum}/${ws}/windows/sammelordner/";

      # rsync und rmtree
      # -t Datum belassen
      # -r Rekursiv
      # -o Owner beibehalten
      system("rsync -tor --delete $sammelordner $lehrer_pfad");
      system("rsync -tr $sammelordner $log_pfad_ka");
      print "<b>  ... Räume Computer $ws auf ...  </b>";
      # Daten auf der Workstation löschen
      rmtree("/home/workstations/${raum}/${ws}/windows"); 
      &setup_verzeichnis("/home/workstations/\$raeume/\$workstation/windows",
                         "/home/workstations/$raum/$ws/windows",
                         "$ws");
      &setup_verzeichnis("/home/workstations/\$raeume/\$workstation/windows/sammelordner",
                         "/home/workstations/$raum/$ws/windows/sammelordner",
                         "$ws");


      print "<b> ... fertig</b><br>";
   }

   print "<p>";
   # Aufgaben einsammeln
   print "<b>Sammle Aufgaben ein ... ";
   # rsync und rmtree
   system("rsync -tor --delete $aufgaben $lehrer_verzeichnis");
   system("rsync -tr $aufgaben $log_verzeichnis");
   # Alles soll lehrer gehören
   system("chown -R ${loginname}:lehrer $lehrer_verzeichnis");
   # Alles soll root gehören
   system("chown -R root:root $log_verzeichnis");
   # Daten auf der Workstation löschen
   rmtree("/home/klassenarbeit/${raum}/aufgaben");       
   &setup_verzeichnis("/home/klassenarbeit/\$raeume/aufgaben",
                      "/home/klassenarbeit/$raum/aufgaben",
                      "admin",
                      "$raum");
   print "... fertig.</b><p> ";
}


sub unterricht_einsammeln {
  # Parameter 1: Wer sammelt ein
  # Parameter 2: In welcher Klasse wird eingesammelt 
  # Parameter 3: Original (mv) oder Kopie (rsync)
  my ($loginname, $klasse, $orig) = @_;
  my $lehrer_login="";
  my $date=&zeit_stempel;

  # Dateinamen ermitteln
  my $sammelordner="";
  my $lehrer_pfad ="";
  my $lehrer_verzeichnis="/home/lehrer/${loginname}/windows/sammelordner/U-${klasse}_${date}";
  my $aufgaben="/home/aufgaben/${klasse}/${loginname}";
  my @klasse = &get_schueler_in_klasse($klasse);

  # Verzeichnis Anlegen
  # repair.directories einlesen
  &get_alle_verzeichnis_rechte();
  # Sicherstellen, dass der sammelordner beim Lehrer existiert
  &setup_verzeichnis("/home/lehrer/\$lehrer/windows/sammelordner",
                     "/home/lehrer/$loginname/windows/sammelordner",
                     "$loginname");
  # gehört erstmal root
  &check_verzeichnis_mkdir("${lehrer_verzeichnis}");

  foreach my $schueler (@klasse) {
      print "<b> Sammle $schueler ein ... </b>";
      $lehrer_pfad ="$lehrer_verzeichnis/${schueler}";
 
      &check_verzeichnis_mkdir("${lehrer_pfad}");

      $sammelordner = "/home/schueler/${klasse}/${schueler}/windows/sammelordner/";

      # rsync und rmtree
      # -t Datum belassen
      # -r Rekursiv
      # -o Owner beibehalten
      if ($orig eq "yes") {
         system("mv $sammelordner/* $lehrer_pfad");
         &setup_verzeichnis("/home/schueler/\$klassen/\$schueler/windows/sammelordner",
                            "/home/schueler/$klasse/$schueler/windows/sammelordner",
                            "$schueler");
      } else {
         system("rsync -tor --delete $sammelordner $lehrer_pfad");
      }
      print "<b> $schueler in $klasse ... fertig</b><br>";
   }

   print "<p>";
   # Aufgaben einsammeln
   print "<b>Sammle Aufgaben ein ...";
   if ($orig eq "yes") {
      # mv 
      system("mv $aufgaben $lehrer_verzeichnis");
   } else {
      # rsync
      system("rsync -tor --delete $aufgaben $lehrer_verzeichnis");
   }
   # Alles soll lehrer gehören
   system("chown -R ${loginname}:lehrer $lehrer_verzeichnis");
   print "Aufgaben Einsammeln ... fertig.</b><p> ";
}



# ENDE DER DATEI
# Wert wahr=1 zurückgeben
1;
