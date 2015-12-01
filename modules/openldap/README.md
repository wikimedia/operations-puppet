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

When using the mirror_mode option, the replication user (cn=repluser)
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
dn: cn=repluser,$suffix
objectClass: person
objectClass: top
cn: repluser
sn: repluser
userPassword: HASH_AS_ABOVE
