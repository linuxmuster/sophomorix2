#!/usr/bin/make
# Dies ist das sophomorix Makefile bis zur Version 0.9.x

# Zur Erstellung des Debian-Pakets notwendig (make DESTDIR=/root/sophomorix)
DESTDIR=

# Debian
#====================================

# Homes
HOME=$(DESTDIR)/home

# Developement
USERROOT=$(DESTDIR)/root

#Daten
LIBDIR=$(DESTDIR)/var/lib/sophomorix

# Debian
WEBMINDEBDIR=$(DESTDIR)/usr/share/webmin

# Dokumentation
DOCDEBDIR=$(DESTDIR)/usr/share/doc

# SAMBADEBCONFDIR für Debian 
SAMBADEBCONFDIR=$(DESTDIR)/etc/samba

# SAMBA Debian 
SAMBADIR=$(DESTDIR)/var/lib/samba

# WEBMINCONFDIR ML und Debian
WEBMINCONFDIR=$(DESTDIR)/etc/webmin

all: install-base install-files install-developer


# sophomorix-base
install-base:
	##### some dirs
	install -d -m700 -oroot -groot $(DESTDIR)/var/lib/sophomorix
	install -d -m700 -oroot -groot $(DESTDIR)/var/log/sophomorix
	install -d -m700 -oroot -groot $(DESTDIR)/var/log/sophomorix/user
	install -d -m700 -oroot -groot $(DESTDIR)/var/lib/sophomorix/drucken

	##### scripts
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-base/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### configs for admin
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/user
	install -oroot -groot --mode=0600 sophomorix-base/config/*[!CVS] $(DESTDIR)/etc/sophomorix/user
	##### configs for developers
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/user
	install -oroot -groot --mode=0700 sophomorix-base/config-devel/*[!CVS] $(DESTDIR)/etc/sophomorix/devel/user
	##### Copy the DB-independant libs
#	install -oroot -groot --mode=0744 sophomorix-base/lib/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### Copy the module
	install -d -m755 -oroot -groot $(DESTDIR)/usr/lib/perl5/Sophomorix
	install -oroot -groot --mode=0644 sophomorix-base/modules/Sophomorix*[a-z1-9] $(DESTDIR)/usr/lib/perl5/Sophomorix


install-files:
	##### lib for managing users in files (passwd, group, user.protokoll)
	install -oroot -groot --mode=0744 sophomorix-files/lib/sophomorix*[a-z1-9] $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-files/scripts/sophomorix*[a-z1-9] $(DESTDIR)/usr/sbin


install-developer:
	##### tset and developement tools
	install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix*[a-z1-9] $(DESTDIR)/usr/sbin


# sophomorix-webmin
#install-webmin:
#	# nothing to do
#	# configs for admin
#	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config/* $(DESTDIR)/etc/sophomorix/webmin
#	# configs for developers
#	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/webmin
#	install -oroot -groot --mode=0700 sophomorix-base/config-devel/* $(DESTDIR)/etc/sophomorix/devel/webmin



# sophomorix-webmin
#install-webmin-classmanager:
#	# configs for developers
#	install -d -m700 -oroot -groot $(WEBMINDEBDIR)/classmanager
#	install -oroot -groot --mode=0700 sophomorix-webmin-classmanager/*.cgi $(WEBMINDEBDIR)/classmanager
#	install -d -m700 -oroot -groot $(WEBMINDEBDIR)/classmanager/help
#	install -oroot -groot --mode=0700 sophomorix-webmin-classmanager/help/*.html $(WEBMINDEBDIR)/classmanager/help
#	install -d -m700 -oroot -groot $(WEBMINDEBDIR)/classmanager/images
#	install -oroot -groot --mode=0700 sophomorix-webmin-classmanager/images/ $(WEBMINDEBDIR)/classmanager/help




# sophomorix-usermin
install-usermin:
	# nothing to do
