# The gridmaster parameter is used in the template to preseed the package
# installation with the (annoyingly) semi-hardcoded FQDN to the grid
# master server.
#
# $etcdir *needs* to be shared between all instances that are
# part of the grid; normally it should reside on a network
# filesystem.
#
# This is also normally a requirement of a HA installation of
# gridengine, and the default for Toolforge (which bind mounts
# /var/lib/gridengine to a subdirectory of /data/project).
#
# Annoyingly, $etcdir is set in several places all over the module
# because there is no (reliable) way to have defines reuse the
# definition.  If you change it here, you must change it everywhere.

class gridengine($gridmaster) {

    file { '/var/local/preseed':
        ensure => directory,
        mode   => '0600',
    }

    file { '/var/local/preseed/gridengine.preseed':
        ensure  => 'file',
        mode    => '0600',
        backup  => false,
        content => template('gridengine/gridengine.preseed.erb'),
        require => File['/var/local/preseed'],
    }

    package { 'gridengine-common':
        ensure       => latest,
        responsefile => '/var/local/preseed/gridengine.preseed',
        require      => File['/var/local/preseed/gridengine.preseed'],
    }

    $etcdir = '/var/lib/gridengine/etc'

    file { $etcdir:
        ensure  => directory,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        force   => true,
        recurse => false,
        purge   => true,
    }

    file { "${etcdir}/hosts":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${etcdir}/hosts/${::fqdn}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/gridengine-mailer':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/gridengine-mailer',
    }
}
