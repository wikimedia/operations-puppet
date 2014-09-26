# vim: set ts=2 sw=2 et :
# misc/icinga.pp

class icinga::monitor {

    include facilities::pdu_monitoring
    include icinga::ganglia::ganglios
    include icinga::monitor::checkpaging
    include icinga::monitor::files::misc
    include icinga::nsca::firewall
    include icinga::nsca::daemon
    include icinga::monitor::wikidata
    include icinga::groups::misc
    include lvs::monitor
    include dsh::config
    include mysql
    include nagios::gsbmonitoring
    include nrpe
    include passwords::nagios::mysql
    include certificates::globalsign_ca

    class { 'icinga':            }
    class { 'icinga::web':       }
    class { 'icinga::naggen':    }
}

# Nagios/icinga configuration files

class icinga::monitor::configuration::variables {

    # This variable declares the monitoring hosts It is called master hosts as
    # monitor_host is already a service.
    $master_hosts = [ 'neon.wikimedia.org' ]

    $icinga_config_dir = '/etc/icinga'
    $nagios_config_dir = '/etc/nagios'
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

    # fix permissions on all individual service files
    exec { 'fix_nagios_perms':
        command => '/bin/chmod -R a+r /etc/nagios';
    }
    exec { 'fix_icinga_perms':
        command => '/bin/chmod -R a+r /etc/icinga';
    }
    exec { 'fix_icinga_temp_files':
        command => '/bin/chown -R icinga /var/lib/icinga';
    }
    exec { 'fix_nagios_plugins_files':
        command => '/bin/chmod -R a+w /var/lib/nagios';
    }
    exec { 'fix_icinga_command_file':
        command => '/bin/chmod a+rw /var/lib/nagios/rw/nagios.cmd';
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

class icinga::ganglia::ganglios {
    include ganglia::collector::config

    package { 'ganglios':
        ensure => 'installed',
    }

    cron { 'ganglios-cron':
        ensure  => present,
        command => 'test -w /var/log/ganglia/ganglia_parser.log && /usr/sbin/ganglia_parser',
        user    => 'icinga',
        minute  => '*/2',
    }

    file { '/var/lib/ganglia/xmlcache':
        ensure => directory,
        mode   => '0755',
        owner  => 'icinga',
    }

}
