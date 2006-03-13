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

# Data
LOGDIR=$(DESTDIR)/var/log/sophomorix

# Perl modules
PERLMOD=$(DESTDIR)/usr/share/perl5/Sophomorix

# Debian
#WEBMINDEBDIR=$(DESTDIR)/usr/share/webmin

# Dokumentation
DOCDEBDIR=$(DESTDIR)/usr/share/doc

# Developer
CONF=$(DESTDIR)/etc/sophomorix

# Schema
SCHEMA=$(DESTDIR)/etc/ldap/schema

# Developer
DEVELCONF=$(DESTDIR)/usr/share/sophomorix

# Developer
LANGUAGE=$(DESTDIR)/usr/share/sophomorix/lang

# SAMBADEBCONFDIR für Debian 
SAMBADEBCONFDIR=$(DESTDIR)/etc/samba

# SAMBA Debian 
SAMBADIR=$(DESTDIR)/var/lib/samba

# Config-templates
CTEMPDIR=$(DESTDIR)/usr/share/sophomorix/config-templates

# Config-templates
DEVELOPERDIR=$(DESTDIR)/usr/share/sophomorix-developer

# WEBMINCONFDIR ML und Debian
#WEBMINCONFDIR=$(DESTDIR)/etc/webmin

# Tools
TOOLS=$(DESTDIR)/root/sophomorix-developer

# dbconfig-common/install
DBINSTALL=$(DESTDIR)/usr/share/dbconfig-common/data/sophomorix-pgldap/install

# dbconfig-common/install
DBADMININSTALL=$(DESTDIR)/usr/share/dbconfig-common/data/sophomorix-pgldap/install-dbadmin

# dbconfig-common/upgrade
DBUPGRADE=$(DESTDIR)/usr/share/dbconfig-common/data/sophomorix-pgldap/upgrade



all: install-base install-files install-sys-files install-pgldap install-sys-pgldap install-vampire install-developer

clean: clean-doc



# sophomorix-base
install-base:
	##### some dirs
	install -d -m700 -oroot -groot $(LIBDIR)
	install -d -m700 -oroot -groot $(LIBDIR)/tmp
	install -d -m700 -oroot -groot $(LIBDIR)/print-data
	install -d -m700 -oroot -groot $(LIBDIR)/database
	install -d -m700 -oroot -groot $(LOGDIR)
	install -d -m700 -oroot -groot $(LOGDIR)/user
	install -d -m700 -oroot -groot $(CTEMPDIR)
	install -d -m700 -oroot -groot $(CTEMPDIR)/samba/netlogon

	##### scripts
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-base/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### teacher scripts
	install -d $(DESTDIR)/usr/bin
	# group owner is changed in postinst-script to lehrer
	install -oroot -groot --mode=4750 sophomorix-base/scripts-teacher/sophomorix-*[a-z1-9] $(DESTDIR)/usr/bin
	##### configs for admin
	install -d -m755 -oroot -groot $(CONF)/user
	install -oroot -groot --mode=0644 sophomorix-base/config/sophomorix.conf $(CONF)/user
	install -oroot -groot --mode=0600 sophomorix-base/config/quota.txt $(CONF)/user
	install -oroot -groot --mode=0600 sophomorix-base/config/mailquota.txt $(CONF)/user
	##### config-templates
	install -oroot -groot --mode=0600 sophomorix-base/config-templates/*[!CVS] $(CTEMPDIR)
	##### configs for developers
	install -d -m755 -oroot -groot $(DEVELCONF)/devel

	install -oroot -groot --mode=0644 sophomorix-base/config-devel/sophomorix-devel.conf $(DEVELCONF)/devel
	install -oroot -groot --mode=0600 sophomorix-base/config-devel/repair.directories $(DEVELCONF)/devel
#	install -d -m755 -oroot -groot $(DEVELCONF)/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config-devel/webmin-admin-modules.conf $(DEVELCONF)/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config-devel/webmin-teacher-modules.conf $(DEVELCONF)/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config-devel/webmin-student-modules.conf $(DEVELCONF)/webmin
	##### languages
	install -d -m755 -oroot -groot $(LANGUAGE)

	install -oroot -groot --mode=0644 sophomorix-base/lang/sophomorix-lang.*[a-z] $(LANGUAGE)
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-base/modules/Sophomorix*[A-Za-z1-9].pm $(PERLMOD)
	# for samba
	install -d -m700 -oroot -groot $(DESTDIR)/home/samba/netlogon
	install -oroot -groot --mode=0600 sophomorix-base/samba/netlogon/*.bat.template $(CTEMPDIR)/samba/netlogon

install-files:
	##### lib for managing the user database in plain files
	install -oroot -groot --mode=0744 sophomorix-files/scripts/sophomorix*[a-z1-9] $(DESTDIR)/usr/sbin
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-files/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-pgldap:
	##### patch sophomorix.sql.template BEFORE installation
	##./buildhelper/sopho-sqldbmod
	##### lib for managing the user database in pgldap
	##### scripts
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-pgldap/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-pgldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)
	##### Copy the config
	install -d -m755 -oroot -groot $(CONF)/pgldap/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config/pgldap.conf $(CONF)/pgldap/
	##### Copy the ldap config-templates
	install -d -m755 -oroot -groot $(CTEMPDIR)/ldap/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-ldap/*.template $(CTEMPDIR)/ldap/
	##### Copy the pg config-templates
	install -d -m755 -oroot -groot $(CTEMPDIR)/pg/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/*.template $(CTEMPDIR)/pg/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix.sql $(CTEMPDIR)/pg/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix-admin.sql $(CTEMPDIR)/pg/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix-lang.sql $(CTEMPDIR)/pg/
	##### Copy the pg upgrade files
	install -d -m755 -oroot -groot $(CTEMPDIR)/pg/upgrade
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/db-upgrade/*.sql $(CTEMPDIR)/pg/upgrade/
	##### Copy the pam config-templates
	install -d -m755 -oroot -groot $(CTEMPDIR)/pam/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pam/*.template $(CTEMPDIR)/pam/
	##### Copy the samba config-templates
	install -d -m755 -oroot -groot $(CTEMPDIR)/samba/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-samba/smb.conf.template $(CTEMPDIR)/samba/
	##### install samba.schema
	install -d -m755 -oroot -groot $(SCHEMA)/
	install -oroot -groot --mode=0755 sophomorix-pgldap/config-ldap/samba.schema $(SCHEMA)/
	##### the install script for the database installation
	install -d -m755 -oroot -groot $(DBINSTALL)/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix.sql $(DBINSTALL)/pgsql
	##### the install-dbadmin script for the database installation
	install -d -m755 -oroot -groot $(DBADMININSTALL)/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix-admin.sql $(DBADMININSTALL)/pgsql
	##### the install script for the database installation
	install -d -m755 -oroot -groot $(DBUPGRADE)/
	##### put the update scripts ino place ()
	##### Copy the bdb example file
	install -d -m755 -oroot -groot $(CTEMPDIR)/bdb/
	install -oroot -groot --mode=0644 sophomorix-pgldap/config-bdb/DB_CONFIG $(CTEMPDIR)/bdb/


install-sys-files:
	##### lib for propagating the db to files
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-sys-files/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-sys-pgldap:
	##### lib for propagating the db to pgldap
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-sys-pgldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-vampire:
	##### migration scripts 
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-vampire/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### migration configs
	install -d -m755 -oroot -groot $(CONF)/vampire
	install -oroot -groot --mode=0644 sophomorix-vampire/config/vampire*files $(CONF)/vampire
	install -oroot -groot --mode=0644 sophomorix-vampire/config/vampire*dirs $(CONF)/vampire

#install-ldap:
#	##### Copy the module
#	install -d -m755 -oroot -groot $(PERLMOD)
#	install -oroot -groot --mode=0644 sophomorix-ldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)


install-developer:
	##### test and developement tools
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix-test $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-developer/modules/Sophomorix*[a-z1-9] $(PERLMOD)
	# tools for developing
	##### apt
	install -d $(TOOLS)/apt/s-lists
	install -oroot -groot --mode=0644 sophomorix-developer/tools/apt/s-lists/*sources.list $(TOOLS)/apt/s-lists
	##### testfiles
	install -d $(DEVELOPERDIR)
	install -d $(DEVELOPERDIR)/testfiles
	install -oroot -groot --mode=0755 sophomorix-developer/testfiles/*.txt $(DEVELOPERDIR)/testfiles
	##### script for laptop development
	install -d $(TOOLS)/scripts/laptop
	install -oroot -groot --mode=0755 sophomorix-developer/tools/scripts/laptop/*-cvs $(TOOLS)/scripts/laptop


#install-webmin:
#	install -d $(DESTDIR)/usr/sbin
# moved to sophomorix-base
#	install -oroot -groot --mode=0744 sophomorix-webmin/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
	##### configs for admin
#	install -d -m700 -oroot -groot $(CONF)/user
#	install -oroot -groot --mode=0600 sophomorix-webmin/config/*[!CVS] $(CONF)/user
	##### configs for developers
#	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/user
#	install -oroot -groot --mode=0700 sophomorix-webmin/config-devel/*.txt $(DESTDIR)/etc/sophomorix/devel/user
	# webmin base-configuration
	# Webmin-Kategorien
#	install -d -m755 -oroot -groot $(WEBMINCONFDIR)
#	install -oroot -groot --mode=0644 sophomorix-webmin/config-webmin/*[a-z] $(WEBMINCONFDIR)
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
#install-webmin-classmanager:
#	# the module
#	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager
#	install -oroot -groot --mode=0755 sophomorix-webmin-classmanager/classmanager/*.cgi $(WEBMINDEBDIR)/classmanager
#	install -oroot -groot --mode=0755 sophomorix-webmin-classmanager/classmanager/module.info $(WEBMINDEBDIR)/classmanager
#	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager/help
#	install -oroot -groot --mode=0644 sophomorix-webmin-classmanager/classmanager/help/*.html $(WEBMINDEBDIR)/classmanager/help
#	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager/images
#	install -oroot -groot --mode=0644 sophomorix-webmin-classmanager/classmanager/images/*.gif $(WEBMINDEBDIR)/classmanager/images
#	install -d -m755 -oroot -groot $(WEBMINDEBDIR)/classmanager/lang
#	install -oroot -groot --mode=0644 sophomorix-webmin-classmanager/classmanager/lang/*[!CVS] $(WEBMINDEBDIR)/classmanager/lang






clean-doc:
	rm -rf sophomorix-doc/html

# you need to: 
#       apt-get install docbook-utils
# on debian to create documentation
doc:
	# Creating html-documentation
	cd ./sophomorix-doc/source/sgml; docbook2html --nochunks --output ../../html  sophomorix.sgml
	cd ./sophomorix-doc/source/sgml; docbook2html --nochunks --output ../../html  changelog.sgml
	# Copying the pictures
	cp ./sophomorix-doc/source/pictures/pics/splan-*.jpg ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/workflow.png ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/user-status.png ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/project-status.png ./sophomorix-doc/html
	cp ./sophomorix-doc/source/pictures/pics/databases.png ./sophomorix-doc/html
	# Creating html-manpages
	buildhelper/sopho-man2html
	# Creating changelog
	buildhelper/sopho-changelog


# sophomorix-usermin
install-usermin:
	# nothing to do
