# profile class for labs monitoring specific stuff

class profile::labs::monitoring (
    $monitoring_master = hiera('profile::openstack::main::statsd_host'),
    $monitoring_standby = hiera('profile::openstack::main::statsd_host_standby'),
) {
    $packages = [
        'python-keystoneauth1',
        'python-keystoneclient',
        'python-novaclient',
        'libapache2-mod-uwsgi',
        'rsync',
    ]

    package { $packages:
        ensure => 'present',
    }

    #
    # hourly cron to rsync whisper files
    #
    ssh::userkey { '_graphite':
        ensure  => 'present',
        content => secret('ssh/wmcs/monitoring/wmcs_monitoring_rsync.pub'),
    }

    file { '/var/lib/graphite/.ssh':
        ensure => directory,
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0700',
    }

    file { '/var/lib/graphite/.ssh/id_rsa':
        content   => secret('ssh/wmcs/monitoring/wmcs_monitoring_rsync.priv'),
        owner     => '_graphite',
        group     => '_graphite',
        mode      => '0600',
        require   => File['/var/lib/graphite/.ssh'],
        show_diff => false,
    }

    # master / slave specific bits
    if $facts['fqdn'] == $monitoring_master {
        $cron_ensure = 'absent'

        ferm::service { 'wmcs_monitoring_rsync_ferm':
            proto  => 'tcp',
            port   => '22',
            srange => "@resolve(${monitoring_standby})",
        }

        package { 'rssh':
            ensure => present,
        }

        file { '/etc/rssh.conf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "allowrsync\nuser=_graphite:011:100000:\n",
        }

        user { '_graphite':
            ensure => present,
            shell  => '/usr/bin/rssh',
        }
    } else {
        $cron_ensure = 'present'

        user { '_graphite':
            ensure => present,
            shell  => '/bin/false',
        }
    }

    $whisper_dir = '/srv/carbon/whisper/'
    cron { 'wmcs_monitoring_rsync_cronjob':
        ensure  => $cron_ensure,
        command => "/usr/bin/rsync --delete --delete-after -aSO ${monitoring_master}:${whisper_dir} ${whisper_dir}",
        minute  => 00,
        hour    => '*/8',
        user    => '_graphite',
        require => Package['rsync'],
    }
}
