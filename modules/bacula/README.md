# Bacula Puppet Module #

A Puppet module for installing and managing all the aspects of bacula backup system.

## Requirements ##
- A Debian like distro (e.g. Ubuntu)
- An understanding of the bacula architecture and its resources.
A good starting point is http://www.bacula.org/2.4.x-manuals/en/main/bacula-applications.png

## Notes ##

This module will have all Control channel communications as well as the actual data
storage encrypted using the PKI infrastructure provided by puppet

## Usage ##
### Configure your director ###

Setup director using mysql backend

	class { 'bacula::director':
	    sqlvariant          => 'mysql',
	    max_dir_concur_jobs => '10',
	}

Define the database to be used (it should be configured by the package)

	bacula::director::catalog { 'MYDB':
	    dbname      => 'bacula',
	    dbuser      => 'bacula',
	    dbhost      => 'bacula-db.example.org',
	    dbport      => '3306',
	    dbpassword  => 'bacula',
	}

Defined a schedule

	bacula::director::schedule { 'Monthly-Sat':
	    runs => [
	                { 'level' => 'Full', 'at' => '1st Sat at 06:00', },
	                { 'level' => 'Differential', 'at' => '2nd Sat at 06:00', },
	                { 'level' => 'Incremental', 'at' => 'sun-fri at 07:00', },
	            ],
	}

Define a pool with your Volumes (Tapes, Files of otherwise)
The `storage` parameter will be defined later on the storage daemon

	bacula::director::pool { 'mypool':
	    max_vols         => 10,
	    storage          => 'mystor',
	    volume_retention => '20 days',
	}

Define a FileSet containing all you want to backup
The `name` of the resource should not contain slashes ('/')

	bacula::director::fileset { 'root-var':
	    includes     => [ '/', '/var',],
	    excludes     => [ '/tmp', ],
	}

And create a job with defaults for our jobs. They will be used on the client

	bacula::director::jobdefaults { '1st-sat-mypool':
	    when        => '1st-Sat',
	    pool        => 'mypool',
	}

### Configure your storage daemon(s) ###

Install the mysql variant of the director.
The ```director``` is the FQDN of our director machine

	class { 'bacula::storage':
	    director            => 'dir.example.com',
	    sd_max_concur_jobs  => 5,
	    sqlvariant          => 'mysql',
	}

Define two storages, one with File backend and one with Tape.
The ```name``` parameter should be the same with the ```storage``` parameter
the pool resource in the director 

	bacula::storage::device { 'FileStorage':
	    device_type     => 'File',
	    media_type      => 'File',
	    archive_device  => '/srv/backups',
	    max_concur_jobs => 2,
	}
	
	bacula::storage::device { 'Tapes':
	    device_type     => 'Tape',
	    media_type      => 'LTO4',
	    archive_device  => '/dev/nst0',
	    max_concur_jobs => 2,
	    spool_dir       => '/tmp/spool',
	    max_spool_size  => '32212254720',
	}

### Configure your client (fd) deamons ###

Install the mysql variant of the director.
The ```director``` is the FQDN of our director machine
The ```catalog``` parameter is the ```name``` of the catalog defined
in the director part

	class { 'bacula::client':
	    director        => 'dir.example.com',
	    catalog         => 'example',
	    file_retention  => '60 days',
	    job_retention   => '6 months',
	}

Define two jobs using one of the filesets defined earlier and the defaults
from some jobdefaults resource

	bacula::client::job { "rootfs-ourdefaults":
	    fileset     => 'root',
	    jobdefaults => 'ourdefaults',
	}

	bacula::client::job { "varfs-ourdefaults":
	    fileset     => 'root',
	    jobdefaults => 'ourdefaults',
	}
