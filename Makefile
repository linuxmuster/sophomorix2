#!/usr/bin/make
# This is the sophomorix Makefile
# $Id$
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

# Cache
CACHEDIR=$(DESTDIR)/var/cache/sophomorix

# Logs
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

# Language
LANGUAGE=$(DESTDIR)/usr/share/sophomorix/lang

# Filter
FILTER=$(DESTDIR)/usr/share/sophomorix/filter

# SAMBADEBCONFDIR für Debian 
SAMBADEBCONFDIR=$(DESTDIR)/etc/samba

# SAMBA Debian 
SAMBADIR=$(DESTDIR)/var/lib/samba

# Config-templates
CTEMPDIR=$(DESTDIR)/usr/share/sophomorix/config-templates

# Testfiles
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
# obsolete ???
DBUPGRADE=$(DESTDIR)/usr/share/dbconfig-common/data/sophomorix-pgldap/upgrade



all: install-base install-pgldap install-sys-pgldap install-vampire install-developer

help:
	@echo ' '
	@echo 'Most common options of this Makefile:'
	@echo '-------------------------------------'
	@echo ' '
	@echo '   make help'
	@echo '      show this help'
	@echo ' '
	@echo '   make'
	@echo '      make an installation of files to the local debian system'
	@echo ' '
	@echo '   make deb'
	@echo '      create a debian package'
	@echo ' '
	@echo '   make lenny'
	@echo '   make deb'
	@echo '      create a debian lenny package'
	@echo ' '
	@echo '   make ubuntu'
	@echo '   make deb'
	@echo '      create a debian package'
	@echo ' '

# build a package
deb:
	### deb
	### Prepare to build an debian etch package
	cp sophomorix-pgldap/config-pg/sophomorix-admin.sql.etch sophomorix-pgldap/config-pg/sophomorix-admin.sql
	cp debian/control.etch debian/control
	cp sophomorix-pgldap/config-ldap/ldap.conf.template.etch sophomorix-pgldap/config-ldap/ldap.conf.template
	cp sophomorix-pgldap/config-ldap/slapd-standalone.conf.template.etch sophomorix-pgldap/config-ldap/slapd-standalone.conf.template
	@echo 'Did you do a dch -i ?'
	@sleep 8
	dpkg-buildpackage -tc -uc -us -sa -rfakeroot
	@echo ''
	@echo 'Do not forget to tag this version in cvs'
	@echo ''

ubuntu:
	### Prepare to build an ubuntu package
	cp sophomorix-pgldap/config-pg/sophomorix-admin.sql.ubuntu sophomorix-pgldap/config-pg/sophomorix-admin.sql
	cp debian/control.ubuntu debian/control
	cp sophomorix-pgldap/config-ldap/ldap.conf.template.ubuntu sophomorix-pgldap/config-ldap/ldap.conf.template
	cp sophomorix-pgldap/config-ldap/slapd-standalone.conf.template.ubuntu sophomorix-pgldap/config-ldap/slapd-standalone.conf.template
	@echo 'Did you do a dch -i ?'
	@sleep 8
	dpkg-buildpackage -tc -uc -us -sa -rfakeroot
	@echo ''
	@echo 'Do not forget to tag this version in cvs'
	@echo ''

lenny:
	### Prepare to build an lenny package
	cp sophomorix-pgldap/config-pg/sophomorix-admin.sql.lenny sophomorix-pgldap/config-pg/sophomorix-admin.sql
	cp debian/control.lenny debian/control
	cp sophomorix-pgldap/config-ldap/ldap.conf.template.lenny sophomorix-pgldap/config-ldap/ldap.conf.template
	cp sophomorix-pgldap/config-ldap/slapd-standalone.conf.template.lenny sophomorix-pgldap/config-ldap/slapd-standalone.conf.template
	@echo 'Did you do a dch -i ?'
	@sleep 8
	dpkg-buildpackage -tc -uc -us -sa -rfakeroot
	@echo ''
	@echo 'Do not forget to tag this version in cvs'
	@echo ''


clean: clean-doc clean-debian

clean-debian:
	rm -rf  debian/sophomorix

# sophomorix-base
install-base:
	### install-base
# some dirs
	@install -d -m700 -oroot -groot $(LIBDIR)
	@install -d -m700 -oroot -groot $(LIBDIR)/tmp
	@install -d -m700 -oroot -groot $(LIBDIR)/lock
	@install -d -m700 -oroot -groot $(LIBDIR)/print-data
	@install -d -m755 -oroot -groot $(CACHEDIR)
	@install -d -m700 -oroot -groot $(LOGDIR)
	@install -d -m700 -oroot -groot $(LOGDIR)/user
	@install -d -m700 -oroot -groot $(CTEMPDIR)
	@install -d -m700 -oroot -groot $(CTEMPDIR)/samba/netlogon
	@install -d -m700 -oroot -groot $(CTEMPDIR)/apache
# scripts
	@install -d $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-base/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
# teacher scripts
	@install -d $(DESTDIR)/usr/bin
# group owner is changed in postinst-script to lehrer
	@install -oroot -groot --mode=4750 sophomorix-base/scripts-teacher/sophomorix-*[a-z1-9] $(DESTDIR)/usr/bin
# installing configs for root
	@install -d -m755 -oroot -groot $(CONF)/user
	@install -oroot -groot --mode=0644 sophomorix-base/config/sophomorix.conf $(CONF)/user
	@install -oroot -groot --mode=0600 sophomorix-base/config/quota.txt $(CONF)/user
	@install -oroot -groot --mode=0600 sophomorix-base/config/mailquota.txt $(CONF)/user
	@install -d -m755 -oroot -groot $(CONF)/project
	@install -oroot -groot --mode=0644 sophomorix-base/config/projects.create $(CONF)/project
	@install -oroot -groot --mode=0644 sophomorix-base/config/projects.update $(CONF)/project
# config-templates
	@install -oroot -groot --mode=0600 sophomorix-base/config-templates/*.txt $(CTEMPDIR)
	@install -oroot -groot --mode=0600 sophomorix-base/config-templates/*.map $(CTEMPDIR)
	@install -oroot -groot --mode=0600 sophomorix-base/config/sophomorix.conf $(CTEMPDIR)
# configs for developers
	@install -d -m755 -oroot -groot $(DEVELCONF)/devel
	@install -oroot -groot --mode=0644 sophomorix-base/config-devel/sophomorix-devel.conf $(DEVELCONF)/devel
	@install -oroot -groot --mode=0644 sophomorix-base/config-devel/sophomorix-support.conf $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repair.directories $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repairhome.administrator $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repairhome.teacher $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repairhome.student $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repairhome.examaccount $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repairhome.attic $(DEVELCONF)/devel
	@install -oroot -groot --mode=0600 sophomorix-base/config-devel/repairhome.domcomp $(DEVELCONF)/devel
#	install -d -m755 -oroot -groot $(DEVELCONF)/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config-devel/webmin-admin-modules.conf $(DEVELCONF)/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config-devel/webmin-teacher-modules.conf $(DEVELCONF)/webmin
#	install -oroot -groot --mode=0600 sophomorix-base/config-devel/webmin-student-modules.conf $(DEVELCONF)/webmin
# languages
	@install -d -m755 -oroot -groot $(LANGUAGE)
	@install -oroot -groot --mode=0644 sophomorix-base/lang/sophomorix-lang.*[a-z] $(LANGUAGE)
	@install -oroot -groot --mode=0644 sophomorix-base/lang/errors.*[a-z] $(LANGUAGE)
	@install -d -m755 -oroot -groot $(LANGUAGE)/latex-templates
	@install -oroot -groot --mode=0644 sophomorix-base/latex-templates/*.tex $(LANGUAGE)/latex-templates
# filter scripts
	@install -d -m755 -oroot -groot $(FILTER)
	@install -oroot -groot --mode=0755 sophomorix-base/filter/*-filter $(FILTER)
	@install -oroot -groot --mode=0755 sophomorix-base/filter/*-schueler $(FILTER)
# Copy the module
	@install -d -m755 -oroot -groot $(PERLMOD)
	@install -oroot -groot --mode=0644 sophomorix-base/modules/Sophomorix*[A-Za-z1-9].pm $(PERLMOD)
# for samba
	@install -d -m700 -oroot -groot $(DESTDIR)/home/samba/netlogon
	@install -oroot -groot --mode=0600 sophomorix-base/samba/netlogon/*.bat.template $(CTEMPDIR)/samba/netlogon

install-files:
	### install-files
##### lib for managing the user database in plain files
	install -oroot -groot --mode=0744 sophomorix-files/scripts/sophomorix*[a-z1-9] $(DESTDIR)/usr/sbin
##### Copy the module
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-files/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-pgldap:
	### install-pgldap
# patch sophomorix.sql.template BEFORE installation
# ./buildhelper/sopho-sqldbmod
# installing lib for managing the user database in pgldap
# scripts
	@install -d $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-pgldap/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
# postgres2slapd scripts
	@install -oroot -groot --mode=0744 sophomorix-pgldap/postgres2slapd/dump-postgres-for-ldap.sh $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-pgldap/postgres2slapd/gen-ldif-from-sql.perl $(DESTDIR)/usr/sbin
# Copy the module
	@install -d -m755 -oroot -groot $(PERLMOD)
	@install -oroot -groot --mode=0644 sophomorix-pgldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)
# Copy the config
	@install -d -m755 -oroot -groot $(CONF)/pgldap/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config/pgldap.conf $(CONF)/pgldap/
# Copy the ldap config-templates
	@install -d -m755 -oroot -groot $(CTEMPDIR)/ldap/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-ldap/*.template $(CTEMPDIR)/ldap/
# Copy the upgrade scripts
	@install -d -m755 -oroot -groot $(CTEMPDIR)/scripts/
	@install -d -m755 -oroot -groot $(CTEMPDIR)/scripts/upgrade/
	@install -oroot -groot --mode=0744 sophomorix-base/upgrade-scripts/*.upgrade $(CTEMPDIR)/scripts/upgrade/
# Copy the pg config-templates
	@install -d -m755 -oroot -groot $(CTEMPDIR)/pg/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/*.template $(CTEMPDIR)/pg/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix.sql $(CTEMPDIR)/pg/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix-admin.sql $(CTEMPDIR)/pg/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix-lang.sql $(CTEMPDIR)/pg/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/create-index.sql $(CTEMPDIR)/pg/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/drop-index.sql $(CTEMPDIR)/pg/
# Copy the pg upgrade files
	@install -d -m755 -oroot -groot $(CTEMPDIR)/pg/upgrade
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/db-upgrade/*.sql $(CTEMPDIR)/pg/upgrade/
# Copy the pam config-templates
	@install -d -m755 -oroot -groot $(CTEMPDIR)/pam/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pam/*.template $(CTEMPDIR)/pam/
# Copy the samba config-templates
	@install -d -m755 -oroot -groot $(CTEMPDIR)/samba/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-samba/smb.conf.template $(CTEMPDIR)/samba/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-samba/smb.conf.template.linbo $(CTEMPDIR)/samba/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-samba/smb.conf.template.rembo $(CTEMPDIR)/samba/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-samba/smb.conf.template.tivoli $(CTEMPDIR)/samba/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-samba/smb.conf.global $(CTEMPDIR)/samba/
# install samba.schema
	@install -d -m755 -oroot -groot $(SCHEMA)/
	@install -oroot -groot --mode=0755 sophomorix-pgldap/config-ldap/samba.schema $(SCHEMA)/
# Copy the apache-templates
	@install -oroot -groot --mode=0644 sophomorix-base/apache-templates/*-template $(CTEMPDIR)/apache/
# the install script for the database installation
	@install -d -m755 -oroot -groot $(DBINSTALL)/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix.sql $(DBINSTALL)/pgsql
# the install-dbadmin script for the database installation
	@install -d -m755 -oroot -groot $(DBADMININSTALL)/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-pg/sophomorix-admin.sql $(DBADMININSTALL)/pgsql
# the install script for the database installation
# obsolete ???
	@install -d -m755 -oroot -groot $(DBUPGRADE)/
# put the update scripts into place ()
	@install -d -m755 -oroot -groot $(CTEMPDIR)/bdb/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-bdb/DB_CONFIG $(CTEMPDIR)/bdb/
	@install -oroot -groot --mode=0644 sophomorix-pgldap/config-bdb/slapd-standalone.DB_CONFIG $(CTEMPDIR)/bdb/


install-sys-files:
	### install-sys-files
# installing lib for propagating the db to files
	install -d -m755 -oroot -groot $(PERLMOD)
	install -oroot -groot --mode=0644 sophomorix-sys-files/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-sys-pgldap:
	### install-sys-files
# installing lib for propagating the db to pgldap
	@install -d -m755 -oroot -groot $(PERLMOD)
	@install -oroot -groot --mode=0644 sophomorix-sys-pgldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)

install-vampire:
	### install-vampire
# installing vampire scripts 
	@install -d $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-vampire/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
# installing migration configs
	@install -d -m755 -oroot -groot $(CONF)/vampire
	@install -oroot -groot --mode=0644 sophomorix-vampire/config/vampire*files $(CONF)/vampire
	@install -oroot -groot --mode=0644 sophomorix-vampire/config/vampire*dirs $(CONF)/vampire
	@install -oroot -groot --mode=0644 sophomorix-vampire/config/*.config $(CONF)/vampire
	@install -oroot -groot --mode=0644 sophomorix-vampire/config/*.mailsync $(CONF)/vampire
	@install -oroot -groot --mode=0644 sophomorix-vampire/config/*.mailsync.folder $(CONF)/vampire

#install-ldap:
#	##### Copy the module
#	install -d -m755 -oroot -groot $(PERLMOD)
#	install -oroot -groot --mode=0644 sophomorix-ldap/modules/Sophomorix*[a-z1-9] $(PERLMOD)



install-virusscan:
	### install-vampire
# installing virusscan script 
	@install -d $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-virusscan/scripts/sophomorix-virusscan $(DESTDIR)/usr/sbin



install-developer:
	### install-developer
### installing test and developement tools
	@install -d $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix-test $(DESTDIR)/usr/sbin
	@install -oroot -groot --mode=0744 sophomorix-developer/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
# copying perl developer modules
	@install -d -m755 -oroot -groot $(PERLMOD)
	@install -oroot -groot --mode=0644 sophomorix-developer/modules/Sophomorix*[a-z1-9] $(PERLMOD)
# tools for developing
# installing sources.list examples
	@install -d $(TOOLS)/apt/s-lists
	@install -oroot -groot --mode=0644 sophomorix-developer/tools/apt/s-lists/*sources.list $(TOOLS)/apt/s-lists
# installing testfiles
	@install -d $(DEVELOPERDIR)
	@install -d $(DEVELOPERDIR)/testfiles
	@install -oroot -groot --mode=0644 sophomorix-developer/testfiles/*.txt $(DEVELOPERDIR)/testfiles
	@install -d $(DEVELOPERDIR)/projectfiles
	@install -oroot -groot --mode=0644 sophomorix-developer/projectfiles/*.dump $(DEVELOPERDIR)/projectfiles
	@install -d $(TOOLS)/projectdumps
# installing  scripts for laptop development
	@install -d $(TOOLS)/scripts/laptop
	@install -oroot -groot --mode=0755 sophomorix-developer/tools/scripts/laptop/*-cvs $(TOOLS)/scripts/laptop

#install-webmin:
#	install -d $(DESTDIR)/usr/sbin
# moved to sophomorix-base
#	install -oroot -groot --mode=0744 sophomorix-webmin/scripts/sophomorix-*[a-z1-9] $(DESTDIR)/usr/sbin
#	##### configs for admin
#	install -d -m700 -oroot -groot $(CONF)/user
#	install -oroot -groot --mode=0600 sophomorix-webmin/config/*[!CVS] $(CONF)/user
#	##### configs for developers
#	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/user
#	install -oroot -groot --mode=0700 sophomorix-webmin/config-devel/*.txt $(DESTDIR)/etc/sophomorix/devel/user
#	# webmin base-configuration
#	# Webmin-Kategorien
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
	### clean-doc
	rm -rf sophomorix-doc/html

# you need to: 
#       apt-get install docbook-utils
# on debian to create documentation
doc:
	### doc
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
	### install-usermin
# nothing to do
