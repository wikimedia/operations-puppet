class profile::wmcs::backup_glance_images(
    String               $cluster_name    = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::ceph::data_dir'),
    Stdlib::AbsolutePath $admin_keyring   = lookup('profile::ceph::admin_keyring'),
    String               $admin_keydata   = lookup('profile::ceph::admin_keydata'),
    String               $ceph_image_pool = lookup('profile::ceph::client::rbd::pool'),
    String               $backup_interval = lookup('profile::wmcs::backy2::backup_time'),
) {
    class {'::backy2':
        cluster_name => $cluster_name,
    }

    ceph::keyring { 'client.admin':
        keydata => $admin_keydata,
        keyring => $admin_keyring,
    }

    file { '/etc/wmcs_backup_images.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/wmcs/backy2/wmcs_backup_images.yaml.erb');
    }

    file { '/usr/lib/python3/dist-packages/rbd2backy2.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/wmcs/backy2/rbd2backy2.py';
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

    # Script to manage backups
    file { '/usr/local/sbin/wmcs-backup':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/wmcs/backy2/wmcs-backup.py';
    }

    systemd::timer::job { 'backup_glance_images':
        ensure                    => present,
        description               => 'backup images',
        command                   => '/usr/local/sbin/wmcs-backup images backup-all-images',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => $backup_interval,
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team-email',
        user                      => 'root',
        require                   => File['/usr/local/sbin/wmcs-backup'],
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
