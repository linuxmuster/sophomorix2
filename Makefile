#!/usr/bin/make
# Dies ist das sophomorix Makefile bis zur Version 0.9.x

# Zur Erstellung des Debian-Pakets notwendig (make DESTDIR=/root/sophomorix)
DESTDIR=

# Installing from this Makefile
#====================================
# if you use this Makefile to install sophomorix (instead of 
# installing the debian-Package) you will miss:
#   1. html-documentation
#   2. manpages
# This is because debian has scripts to install 1. and 2. VERY easily
# see debian/rules -> dh_installman, dh-installdocs



# Debian
#====================================

# Homes
HOME=$(DESTDIR)/home

# Developement
USERROOT=$(DESTDIR)/root

# Data
LIBDIR=$(DESTDIR)/var/lib/sophomorix

# Perl modules
PERLMOD=$(DESTDIR)/usr/share/perl5/Sophomorix

# Debian
WEBMINDEBDIR=$(DESTDIR)/usr/share/webmin

# Dokumentation
DOCDEBDIR=$(DESTDIR)/usr/share/doc

# SAMBADEBCONFDIR für Debian 
SAMBADEBCONFDIR=$(DESTDIR)/etc/samba

# SAMBA Debian 
SAMBADIR=$(DESTDIR)/var/lib/samba

# Config-templates
CTEMPDIR=$(DESTDIR)/var/lib/sophomorix/config-templates

# WEBMINCONFDIR ML und Debian
WEBMINCONFDIR=$(DESTDIR)/etc/webmin

all: install-base install-files install-sys-files install-developer install-webmin install-webmin-classmanager


# sophomorix-base
install-base:
	##### some dirs
	install -d -m700 -oroot -groot $(DESTDIR)/var/lib/sophomorix
	install -d -m700 -oroot -groot $(DESTDIR)/var/log/sophomorix
	install -d -m700 -oroot -groot $(DESTDIR)/var/log/sophomorix/user
	install -d -m700 -oroot -groot $(DESTDIR)/var/lib/sophomorix/drucken
	install -d -m700 -oroot -groot $(CTEMPDIR)
	install -d -m700 -oroot -groot $(CTEMPDIR)/samba/netlogon

	##### scripts
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-base/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### configs for admin
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/user
	install -oroot -groot --mode=0700 sophomorix-base/config/sophomorix.conf $(DESTDIR)/etc/sophomorix/user
	install -oroot -groot --mode=0600 sophomorix-base/config/quota.txt $(DESTDIR)/etc/sophomorix/user
	##### config-templates
	install -oroot -groot --mode=0600 sophomorix-base/config-templates/*[!CVS] $(CTEMPDIR)
	##### configs for developers
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/user
	install -oroot -groot --mode=0700 sophomorix-base/config-devel/sophomorix-devel.conf $(DESTDIR)/etc/sophomorix/devel/user
	install -oroot -groot --mode=0600 sophomorix-base/config-devel/repair.directories $(DESTDIR)/etc/sophomorix/devel/user
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-base/modules/Sophomorix*[a-z1-9] $(PERLMOD)
	# for samba
	install -d -m700 -oroot -groot $(DESTDIR)/home/samba/netlogon
	install -oroot -groot --mode=0600 sophomorix-base/samba/netlogon/login.bat $(CTEMPDIR)/samba/netlogon

install-files:
	##### lib for managing the user database in plain files
	install -oroot -groot --mode=0744 sophomorix-files/scripts/sophomorix*[a-z1-9] $(DESTDIR)/usr/sbin
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-files/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-sys-files:
	##### lib for propagating the db to files
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-sys-files/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-ldap:
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-ldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)


install-developer:
	##### tset and developement tools
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix-test $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-developer/modules/Sophomorix*[a-z1-9] $(PERLMOD)


install-webmin:
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-webmin/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### configs for admin
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/user
	install -oroot -groot --mode=0600 sophomorix-webmin/config/*[!CVS] $(DESTDIR)/etc/sophomorix/user
	##### configs for developers
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/user
	install -oroot -groot --mode=0700 sophomorix-webmin/config-devel/*.txt $(DESTDIR)/etc/sophomorix/devel/user
	# webmin base-configuration
	# Webmin-Kategorien
	install -d -m755 -oroot -groot $(WEBMINCONFDIR)
	install -oroot -groot --mode=0644 sophomorix-webmin/config-webmin/*[a-z] $(WEBMINCONFDIR)
#	install -oroot -groot --mode=0644 webmin/webmin.cats $(WEBMINCONFDIR)




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
install-webmin-classmanager:
	# the module
	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager
	install -oroot -groot --mode=0755 sophomorix-webmin-classmanager/classmanager/*.cgi $(WEBMINDEBDIR)/classmanager
	install -oroot -groot --mode=0755 sophomorix-webmin-classmanager/classmanager/module.info $(WEBMINDEBDIR)/classmanager
	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager/help
	install -oroot -groot --mode=0644 sophomorix-webmin-classmanager/classmanager/help/*.html $(WEBMINDEBDIR)/classmanager/help
	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager/images
	install -oroot -groot --mode=0644 sophomorix-webmin-classmanager/classmanager/images/*.gif $(WEBMINDEBDIR)/classmanager/images
	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager/lang
	install -oroot -groot --mode=0644 sophomorix-webmin-classmanager/classmanager/lang/*[!CVS] $(WEBMINDEBDIR)/classmanager/lang






# you need to: 
#       apt-get install docbook-utils
# on debian to create documentation
doc:
	# Creating html-documentation
	cd ./sophomorix-doc/source/sgml; docbook2html --nochunks --output ../../html  sophomorix.sgml
	# Copying the pictures
	cp ./sophomorix-doc/source/pictures/pics/splan-*.jpg ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/workflow.png ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/user-status.png ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/project-status.png ./sophomorix-doc/html
	# Creating html-manpages
	buildhelper/sopho-man2html


# sophomorix-usermin
install-usermin:
	# nothing to do
