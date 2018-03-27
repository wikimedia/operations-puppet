# profile class for labs monitoring specific stuff

class profile::labs::monitoring (
    $monitoring_master = hiera('profile::labs::monitoring::master'),
    $monitoring_slave = hiera('profile::labs::monitoring::slave'),
    $whisper_dir = hiera('profile::labs::monitoring::whisper_dir'),
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
    ssh::userkey { '_graphite-sshkey':
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
            srange => '@resolve($monitoring_slave)',
        }
    } else {
        $cron_ensure = 'present'
    }

    cron { 'wmcs_monitoring_rsync_cronjob':
        ensure  => $cron_ensure,
        command => "/usr/bin/rsync --delete --delete-after -aSO ${whisper_dir} ${monitoring_master}:${whisper_dir}/",
        minute  => 00,
        user    => '_graphite',
        require => Package['rsync'],
    }
}
