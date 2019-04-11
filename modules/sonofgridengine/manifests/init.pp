# The gridmaster parameter is used in the template to preseed the package
# installation with the (annoyingly) semi-hardcoded FQDN to the grid
# master server.
#

class sonofgridengine(
    $gridmaster,
    $etcdir = '/var/lib/gridengine/etc',
){

    file { '/var/local/preseed':
        ensure => directory,
        mode   => '0600',
    }

    file { '/var/local/preseed/gridengine.preseed':
        ensure  => 'file',
        mode    => '0600',
        backup  => false,
        content => template('sonofgridengine/gridengine.preseed.erb'),
        require => File['/var/local/preseed'],
    }

    package { 'gridengine-common':
        ensure       => latest,
        responsefile => '/var/local/preseed/gridengine.preseed',
        require      => File['/var/local/preseed/gridengine.preseed'],
    }

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
        source => 'puppet:///modules/sonofgridengine/gridengine-mailer',
    }
}
