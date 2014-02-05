# PostgreSQL/Postgis Puppet Module #

A Puppet module for installing and managing aspects of a PostgreSQL and possibly Postgis system.

## Requirements ##
- A Debian like distro (e.g. Ubuntu)
- Basic understanding of the PostgreSQL database

## Notes ##

This module supports standalone server mode, master/slave server and installation of postgis as well

## Usage ##
### Configure a simple server ###

Just the defaults are good enough for you

	include postgresql::server

In case they don't

	class { 'postgresql::server':
		pgversion => '9.1',
		includes  => ['myconf.conf'],
		port	  => '5555',
		listen_addresses => '127.0.0.1',
	}

	file { '/etc/postgresql/9.1/main/myconf.conf':
		ensure => 'present',
		content => 'my own postgres configuration options', # Or source => etc etc
	}

You want to remove it ?

	class { 'postgresql::server':
		ensure => 'absent',
	}

### Create a user ###

Just define the user

	postgresql::user { 'test@host.example.com':
	  ensure   => 'present',
	  user     => 'test',
	  password => 'test',
	  cidr     => '127.0.0.1/32',
	  type     => 'host',
	  method   => 'trust',
	  database => 'template1',
	}

### Remove a user ###

Just specify absent as ensure

	postgresql::user { 'test@host.example.com':
	  ensure   => 'absent',
	  user     => 'test',
	  password => 'test',
	  cidr     => '127.0.0.1/32',
	  type     => 'host',
	  method   => 'trust',
	  database => 'template1',
	}

### Master/slave mode ###

Set up your master
	class { 'postgresql::master':
		master_server => $::fqdn,
	}

#### Slave node ####
	class { 'postgresql::slave':
		master_server => $::fqdn,
		replication_password => 'mypass',
	}

### Postgis ###

Really simple

	include postgresql::postgis
	postgresql::spatialdb {'mydb': }
