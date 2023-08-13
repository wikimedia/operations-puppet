class profile::wmcs::backy2(
    String               $cluster_name    = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Unixpath     $data_dir        = lookup('profile::cloudceph::data_dir'),
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
