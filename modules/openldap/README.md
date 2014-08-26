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
