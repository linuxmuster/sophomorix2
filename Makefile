#!/usr/bin/make
# Dies ist das sophomorix Makefile bis zur Version 0.9.x


# Zur Erstellung des Debian-Pakets notwendig (make DESTDIR=/root/sophomorix)
DESTDIR=

# Allgemein (Debian und ML 2.0)
#====================================

# Developement
USERROOT=$(DESTDIR)/root

#Daten
LIBDIR=$(DESTDIR)/var/lib/sophomorix

# Debian
WEBMINDEBDIR=$(DESTDIR)/usr/share/webmin


# SuSE
#====================================
# Dokumentation
DOCSUSEDIR=$(DESTDIR)/usr/share/doc/packages


# Debian
#====================================* $(DESTDIR)/usr/sbin

# Dokumentation
DOCDEBDIR=$(DESTDIR)/usr/share/doc

# SAMBADEBCONFDIR für Debian 
SAMBADEBCONFDIR=$(DESTDIR)/etc/samba

# SAMBA Debian 
SAMBADIR=$(DESTDIR)/var/lib/samba

# WEBMINCONFDIR ML und Debian
WEBMINCONFDIR=$(DESTDIR)/etc/webmin


# sophomorix-base
install-base:
	# some dirs
	install -d -m700 -oroot -groot $(DESTDIR)/var/lib/sophomorix
	# scripts
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-base/scripts/sophomorix* $(DESTDIR)/usr/sbin
	# configs for admin
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/user
	install -oroot -groot --mode=0600 sophomorix-base/config/* $(DESTDIR)/etc/sophomorix/user
	# configs for developers
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/user
	install -oroot -groot --mode=0700 sophomorix-base/config-devel/* $(DESTDIR)/etc/sophomorix/devel/user
	# Copy the DB-independant libs
	install -oroot -groot --mode=0744 sophomorix-base/lib/sophomorix* $(DESTDIR)/usr/sbin



# sophomorix-ldap
install-ldap:
	# scripts
	install -d $(DESTDIR)/usr/sbin
	install -oroot -groot --mode=0744 sophomorix-ldap/scripts/sophomorix* $(DESTDIR)/usr/sbin
        # install ldap
	install -d $(DESTDIR)/etc/ldap
	install -d $(DESTDIR)/etc/ldap/schema
	install -oroot -groot --mode=0744 sophomorix-ldap/config/*template $(DESTDIR)/etc/ldap
        # install samba fuer ldap
#	install -d $(DESTDIR)/etc/samba
#	install -oroot -groot --mode=0744 ldap/config-samba/*template $(DESTDIR)/etc/samba
	# schemas
	install -oroot -groot --mode=0744 sophomorix-ldap/schema/*schema $(DESTDIR)/etc/ldap/schema
	# ldif-template
	install -d $(DESTDIR)/etc/sophomorix/devel/ldap
	install -oroot -groot --mode=0744 sophomorix-ldap/ldif/*template $(DESTDIR)/etc/sophomorix/devel/ldap
	# Copy the LDAP-dependant libs
	install -oroot -groot --mode=0744 sophomorix-ldap/lib/sophomorix* $(DESTDIR)/usr/sbin



# sophomorix-webmin
install-webmin:
	# nothing to do
	# configs for admin
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/webmin
	install -oroot -groot --mode=0600 sophomorix-base/config/* $(DESTDIR)/etc/sophomorix/webmin
	# configs for developers
	install -d -m700 -oroot -groot $(DESTDIR)/etc/sophomorix/devel/webmin
	install -oroot -groot --mode=0700 sophomorix-base/config-devel/* $(DESTDIR)/etc/sophomorix/devel/webmin



# sophomorix-webmin
install-webmin-classmanager:
	# configs for developers
	install -d -m700 -oroot -groot $(WEBMINDEBDIR)/classmanager
	install -oroot -groot --mode=0700 sophomorix-webmin-classmanager/*.cgi $(WEBMINDEBDIR)/classmanager
	install -d -m700 -oroot -groot $(WEBMINDEBDIR)/classmanager/help
	install -oroot -groot --mode=0700 sophomorix-webmin-classmanager/help/*.html $(WEBMINDEBDIR)/classmanager/help
	install -d -m700 -oroot -groot $(WEBMINDEBDIR)/classmanager/images
	install -oroot -groot --mode=0700 sophomorix-webmin-classmanager/images/ $(WEBMINDEBDIR)/classmanager/help




# sophomorix-usermin
install-usermin:
	# nothing to do
