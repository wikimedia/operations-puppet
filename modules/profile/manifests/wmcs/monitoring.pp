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

    # master / replica specific bits
    if $::facts['fqdn'] == $monitoring_master {
        $rsync_ensure = 'absent'

        ferm::service { 'wmcs_monitoring_rsync_ferm':
            proto  => 'tcp',
            port   => '22',
            srange => "(@resolve(${monitoring_standby}) @resolve(${monitoring_standby}, AAAA))",
        }

        user { '_graphite':
            ensure => present,
            shell  => '/bin/rbash',
        }
    } elsif $::facts['fqdn'] == $monitoring_standby {
        $rsync_ensure = 'present'

        user { '_graphite':
            ensure => present,
            shell  => '/bin/false',
        }
    } else {
        # all other nodes should have this rsync disable, to avoid overwritting data on-flight
        # sadly, this puppet code only supports 2 nodes (primary/backup) and not something like
        # 1 primary / 3 backups which is the current situation as of this writing.
        $rsync_ensure = 'absent'
    }

    $whisper_dir = '/srv/carbon/whisper/'
    systemd::timer::job { 'wmcs_monitoring_graphite_rsync':
        ensure                    => $rsync_ensure,
        description               => 'Mirror files from Graphite master to standby server',
        command                   => "/usr/bin/rsync --delete --delete-after -aSOrd ${monitoring_master}:${whisper_dir} ${whisper_dir}",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:30:00', # Every hour on the half
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team-email',
        user                      => '_graphite',
    }
}
