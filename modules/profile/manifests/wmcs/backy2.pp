class profile::wmcs::backy2(
    String               $cluster_name    = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Fqdn         $db_host         = lookup('profile::wmcs::backy2::db_host'),
    String               $db_name         = lookup('profile::wmcs::backy2::db_name'),
    String               $db_user         = lookup('profile::wmcs::backy2::db_user'),
    String               $db_pass         = lookup('profile::wmcs::backy2::db_pass'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::ceph::data_dir'),
    Stdlib::AbsolutePath $admin_keyring   = lookup('profile::ceph::admin_keyring'),
    String               $admin_keydata   = lookup('profile::ceph::admin_keydata'),
    String               $ceph_vm_pool    = lookup('profile::ceph::client::rbd::pool'),
    Array[String]        $backup_projects = lookup('profile::wmcs::backy2::backup_projects'),
) {
    class {'::backy2':
        cluster_name => $cluster_name,
        db_host      => $db_host,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
    }

    ceph::keyring { 'client.admin':
        keydata => $admin_keydata,
        keyring => $admin_keyring,
    }

    file { '/etc/wmcs_backup_instances.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/wmcs/backy2/wmcs_backup_instances.yaml.erb');
    }

    file { '/usr/lib/python3/dist-packages/rbd2backy2.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/wmcs/backy2/rbd2backy2.py';
    }

    # Script to backup all VMs that are on ceph and
    #   in projects listed in wmcs_backup_instances.yaml
    file { '/usr/local/sbin/wmcs-backup-instances':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/wmcs/backy2/wmcs-backup-instances.py';
    }

    systemd::timer::job { 'backup_vms':
        ensure                    => present,
        description               => 'snapshot and backup vms in specified projects',
        command                   => '/usr/local/sbin/wmcs-backup-instances',
        interval                  => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* 2:00:00', # daily at 02:00
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-email',
    }

    systemd::timer::job { 'purge_vm_backup':
        ensure                    => present,
        description               => 'purge old VM backups; allow backy2 to decide what is too old',
        command                   => 'for version in `/usr/bin/backy2 -ms ls -e -f uid`; do /usr/bin/backy2 rm $version; done && /usr/bin/backy2 cleanup',
        interval                  => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* 00:05:00', # daily at five past midnight
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-email',
    }
}
