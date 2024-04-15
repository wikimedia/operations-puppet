# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::service(
    $active,
    $version,
    Stdlib::Port $api_bind_port,
    Hash $cinder_backup_volumes,
) {
    class { "openstack::cinder::service::${version}":
        api_bind_port           => $api_bind_port,
    }
    # config should have been declared via a profile, with proper hiera, and is
    # here only for ordering/dependency purposes:
    require "openstack::cinder::config::${version}"

    service { 'cinder-scheduler':
        ensure    => $active,
        require   => Package['cinder-scheduler'],
        subscribe => Class["openstack::cinder::config::${version}"],
    }

    service { 'cinder-api':
        ensure    => $active,
        require   => Package['cinder-api'],
        subscribe => Class["openstack::cinder::config::${version}"],
    }

    rsyslog::conf { 'cinder':
        source   => 'puppet:///modules/openstack/cinder/cinder.rsyslog.conf',
        priority => 20,
    }

    if $cinder_backup_volumes != {} {
        file { '/etc/wmcs-cinder-backup-manager.yaml':
            content   => $cinder_backup_volumes.to_yaml,
            owner     => 'cinder',
            group     => 'cinder',
            mode      => '0440',
            show_diff => false,
        }

        systemd::timer::job { 'backup_cinder_volumes':
            description     => 'Backup select cinder volumes using wmcs-cinder-backup-manager.py',
            command         => '/usr/local/sbin/wmcs-cinder-backup-manager',
            user            => 'root',
            logging_enabled => true,
            logfile_name    => 'wmcs-cinder-backup-manager.log',
            interval        => {
                'start'    => 'OnCalendar',
                'interval' => 'Mon,Wed,Fri *-*-* 10:30:00', # The closer to every two days I could get
            },
        }
    }
}
