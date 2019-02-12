# profile class for WMCS monitoring specific stuff

class profile::wmcs::monitoring (
    String $monitoring_master = lookup('profile::wmcs::monitoring::statsd_master'),
    String $monitoring_standby = lookup('profile::wmcs::monitoring::statsd_standby'),
) {
    require ::profile::openstack::eqiad1::clientpackages

    package { 'rsync':
        ensure => 'present',
    }

    # hourly job to rsync whisper files
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
    if $::facts['fqdn'] == $monitoring_master {
        $rsync_ensure = 'absent'

        ferm::service { 'wmcs_monitoring_rsync_ferm':
            proto  => 'tcp',
            port   => '22',
            srange => "(@resolve(${monitoring_standby}) @resolve(${monitoring_standby}, AAAA))",
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

    # TODO: Remove after change is applied
    cron { 'wmcs_monitoring_rsync_cronjob':
        ensure => absent,
        user   => '_graphite',
    }

    $whisper_dir = '/srv/carbon/whisper/'
    systemd::timer::job { 'wmcs_monitoring_graphite_rsync':
        ensure                    => $rsync_ensure,
        description               => 'Mirror files from Graphite master to standby server',
        command                   => "/usr/bin/rsync --delete --delete-after -aSOrd ${monitoring_master}:${whisper_dir} ${whisper_dir}",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00/8:00:00', # Every 8 hours
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => '_graphite',
    }
}
