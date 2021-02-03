class profile::wmcs::backy2(
    String               $cluster_name    = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::ceph::data_dir'),
    Stdlib::AbsolutePath $admin_keyring   = lookup('profile::ceph::admin_keyring'),
    String               $admin_keydata   = lookup('profile::ceph::admin_keydata'),
    String               $ceph_vm_pool    = lookup('profile::ceph::client::rbd::pool'),
    String               $backup_interval = lookup('profile::wmcs::backy2::backup_time'),
) {
    class {'::backy2':
        cluster_name => $cluster_name,
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

    # Script to manage backups
    file { '/usr/local/sbin/wmcs-backup':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/wmcs/backy2/wmcs-backup.py';
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

    # Script to cleanup expired backups.  Expiration date is
    #   set when the backups are first created.
    file { '/usr/local/sbin/wmcs-purge-backups':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/wmcs/backy2/wmcs-purge-backups.sh';
    }

    systemd::timer::job { 'backup_vms':
        ensure                    => present,
        description               => 'Backup vms assigned to this host',
        command                   => '/usr/local/sbin/wmcs-backup instances backup-assigned-vms',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => $backup_interval,
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team-email',
        user                      => 'root',
    }

    systemd::timer::job { 'purge_vm_backup':
        ensure                    => present,
        description               => 'purge old VM backups; allow backy2 to decide what is too old',
        command                   => '/usr/local/sbin/wmcs-purge-backups',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => '*-*-* 00:05:00', # daily at five past midnight
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team-email',
        user                      => 'root',
    }
}
