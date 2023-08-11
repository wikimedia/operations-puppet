class profile::wmcs::backy2(
    String               $cluster_name    = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::cloudceph::data_dir'),
    String               $ceph_vm_pool    = lookup('profile::cloudceph::client::rbd::pool'),
    String               $backup_interval = lookup('profile::wmcs::backy2::backup_time'),
    String               $db_pass         = lookup('profile::wmcs::backy2::db_pass'),
    String               $backup_dir      = lookup('profile::wmcs::backy2::backup_dir'),
) {
    require profile::cloudceph::auth::deploy
    if ! defined(Ceph::Auth::Keyring['admin']) {
        notify{'profile::wmcs::backy2: Admin keyring not defined, things might not work as expected.': }
    }

    class {'::backy2':
        cluster_name => $cluster_name,
        db_pass      => $db_pass,
        backup_dir   => $backup_dir,
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
        monitoring_contact_groups => 'wmcs-bots',
        monitoring_notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Check_unit_status_of_backup_vms',
        user                      => 'root',
    }

    systemd::timer::job { 'purge_vm_backup':
        ensure                    => present,
        description               => 'purge old VM backups; allow backy2 to decide what is too old',
        command                   => '/usr/local/sbin/wmcs-purge-backups',
        after                     => 'backup_vms.service',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => '*-*-* 00:05:00', # daily at five past midnight
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => '',
        user                      => 'root',
    }

    class {'::postgresql::server':
    }

    postgresql::db { 'backy2':
        owner   => 'backy2',
        require => Class['postgresql::server'];
    }

    postgresql::user { 'backy2':
        ensure   => 'present',
        user     => 'backy2',
        password => $db_pass,
        cidr     => '127.0.0.1/32',
        type     => 'host',
        method   => 'trust',
        database => 'backy2',
        notify   => Exec['initialize-backy2-database'],
    }
}
