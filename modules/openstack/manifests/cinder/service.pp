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

    service { 'cinder-volume':
        ensure    => $active,
        require   => Package['cinder-volume'],
        subscribe => Class["openstack::cinder::config::${version}"],
    }

    rsyslog::conf { 'cinder':
        source   => 'puppet:///modules/openstack/cinder/cinder.rsyslog.conf',
        priority => 20,
    }

    $api_file_to_patch = '/usr/lib/python3/dist-packages/cinder/backup/api.py'
    $api_patch_file = "${api_file_to_patch}.patch"
    file {$api_patch_file:
        source => "puppet:///modules/openstack/${version}/cinder/hacks/backup/api.py.patch",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    exec { "apply ${api_patch_file}":
        command => "/usr/bin/patch --forward ${api_file_to_patch} ${api_patch_file}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${api_file_to_patch} ${api_patch_file}",
        require => [File[$api_patch_file], Package['cinder-api']],
        notify  => Service['cinder-api'],
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
            description               => 'Backup select cinder volumes using wmcs-cinder-backup-manager.py',
            command                   => '/usr/local/sbin/wmcs-cinder-backup-manager',
            user                      => 'root',
            logging_enabled           => true,
            logfile_name              => 'wmcs-cinder-backup-manager.log',
            interval                  => {
                'start'    => 'OnCalendar',
                'interval' => 'Mon,Wed,Fri *-*-* 10:30:00', # The closer to every two days I could get
            },
            monitoring_enabled        => true,
            monitoring_contact_groups => 'wmcs-team-email',
            monitoring_notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Check_unit_status_of_backup_cinder_volumes',
        }
    }
}
