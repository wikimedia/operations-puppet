# OpenLDAP Puppet Module #

A Puppet module for installing and managing an OpenLDAP server

## Requirements ##
- A Debian like distro (e.g. Debian, Ubuntu)
- An understanding of the OpenLDAP architecture and the LDAP protocol

## Usage ##
class { '::openldap':
  server_id = 1,
  suffix = 'dc=example,dc=org',
  datadir = '/var/lib/ldap',
}

## Replication account ##

When using the 'master' option, the replication user (cn=repluser)
needs to be created manually. First create the password hash using
slappasswd -h {SSHA}

(The password hash can be entered in plain text, the conversion to base64
occurs internally.)

Then use the following LDIF file to create the user (e.g using ldapadd):
dn: cn=repluser,$suffix
objectClass: person
objectClass: top
cn: repluser
sn: repluser
userPassword: HASH_AS_ABOVE

## Administrative / rootdn account ##

The slapd.conf template specifies an administrative user (rootdn): cn=admin
This user account needs to be created manually. First create the password hash using
slappasswd -h {SSHA}

(The password hash can be entered in plain text, the conversion to base64
occurs internally.)

Then use the following LDIF file to create the user (e.g using ldapadd):
dn: cn=admin,$suffix
objectClass: person
objectClass: top
cn: admin
sn: admin
userPassword: HASH_AS_ABOVE

## Using slapadd ##

If you got not admin user yet, using LDAP operations is not yet possible. You can break the
chicken and egg problem by using slapadd.

TL;DR

sudo service slapd stop ; sudo -u openldap slapdadd -l ldiffile ; sudo service slapd start

Get slapd stopped, switch privileges to the user openldap, load the server with an LDIF file and then start the server
