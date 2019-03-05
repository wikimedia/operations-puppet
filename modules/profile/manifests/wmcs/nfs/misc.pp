class profile::wmcs::nfs::misc (
    Array[Stdlib::IP::Address] $maps_project_ips = lookup('profile::wmcs::nfs::misc::maps_project_ips'),
    String                     $backup_server    = lookup('profile::wmcs::nfs::misc::backup_server'),
) {

    include profile::wmcs::nfs::backup_keys
    include profile::wmcs::nfs::bdsync
    include profile::wmcs::nfs::snapshot_manager

    ferm::service { 'cloudstore_ssh_backup':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${backup_server})) @resolve((${backup_server}), AAAA))",
    }

    file { '/etc/exports':
        ensure  => present,
        content => template('profile/wmcs/nfs/misc/exports.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/srv/scratch':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '1777',
    }

    file {'/srv/maps':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    mount { '/srv/scratch':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/srv/scratch',
        require => File['/srv/scratch'],
    }

    mount { '/srv/maps':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/srv/maps',
        require => File['/srv/maps'],
    }
}
