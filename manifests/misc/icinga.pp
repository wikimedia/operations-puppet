# vim: set ts=2 sw=2 et :
# misc/icinga.pp

class icinga::monitor::configuration::variables {
    $icinga_config_dir = '/etc/icinga'
}

class icinga::monitor::files::misc {
# Required files and directories
# Must be loaded last

    file { '/etc/icinga/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/nagios':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/cache/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0775',
    }

    file { '/var/lib/nagios/rw':
        ensure => directory,
        owner  => 'icinga',
        group  => 'nagios',
        mode   => '0777',
    }

    file { '/var/lib/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0755',
    }

    # Script to purge resources for non-existent hosts
    file { '/usr/local/sbin/purge-nagios-resources.py':
        source => 'puppet:///files/icinga/purge-nagios-resources.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/log/icinga':
        ensure => directory,
        owner => 'icinga',
        mode => '2757',
    }
    file { '/var/log/icinga/archives':
        ensure => directory,
        owner => 'icinga',
    }
    file { '/var/log/icinga/icinga.log':
        ensure => file,
        owner => 'icinga',
    }
}
