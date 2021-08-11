# sets up NFS exports on a labstore fileserver
class labstore::fileserver::exports(
    Array[String] $server_vols,
    String $drbd_role = 'primary',
){
    require_package(['python3-yaml'])

    group { 'nfsmanager':
        ensure => present,
        name   => 'nfsmanager',
        system => true,
    }

    user { 'nfsmanager':
        home       => '/var/lib/nfsmanager',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/etc/exports.d':
        ensure => directory,
        owner  => 'root',
        group  => 'nfsmanager',
        mode   => '2775',
    }

    $safe_mkdir = sudo::safe_wildcard_cmd('/bin/mkdir -p', '/srv/*')
    $safe_rmdir = sudo::safe_wildcard_cmd('/bin/rmdir', '/srv/*')
    sudo::user { 'nfsmanager':
        privileges => [
            "ALL = NOPASSWD: ${safe_mkdir}",
            "ALL = NOPASSWD: ${safe_rmdir}",
            'ALL = NOPASSWD: /usr/sbin/exportfs',
        ],
        require    => User['nfsmanager'],
    }

    file { '/etc/nfs-mounts.yaml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('labstore/nfs-mounts.yaml.erb'),
        require => [Package['python3'], Package['python3-yaml']],
        notify  => Service['nfs-exportd'],
    }

    # Clean up the bind script following Change-Id: I8fe9cbb84331c527cf3623a2204ceb835c604ff5
    # This script is actively dangerous to failover. See also T169570
    file { '/usr/local/sbin/nfs-manage-binds':
        ensure => absent,
    }


    file { '/usr/local/bin/nfs-exportd':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/nfs-exportd.py',
        require => File['/usr/local/sbin/nfs-manage-binds'],
        notify  => Service['nfs-exportd'],
    }

    file { '/etc/exports.bak':
        ensure  => directory,
        owner   => 'nfsmanager',
        group   => 'nfsmanager',
        require => File['/usr/local/bin/nfs-exportd'],
    }

    systemd::timer::job { 'archive_export_d':
        description => 'Regular jobs for archiving exports.d',
        command     => '/bin/cp -Rp /etc/exports.d /etc/exports.bak',
        user        => 'root',
        interval    => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 0:00:00'},
        require     => File['/etc/exports.bak'],
    }

    # TODO: Remove after initial runs. This just cleans up the old setup.
    file { '/etc/exports.d/public_root.exports':
        ensure => absent,
    }

    file { '/usr/local/sbin/archive-project-volumes':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/archive-project-volumes.py',
    }



    if $drbd_role == 'primary' {
        systemd::service { 'nfs-exportd':
            ensure    => 'present',
            content   => systemd_template('nfs-exportd'),
            require   => File['/usr/local/bin/nfs-exportd'],
            subscribe => File['/etc/novaobserver.yaml'],
        }
    } else {
        systemd::service { 'nfs-exportd':
            ensure         => 'present',
            content        => systemd_template('nfs-exportd'),
            require        => File['/usr/local/bin/nfs-exportd'],
            service_params => {
                ensure => 'stopped',
                enable => false,
            }
        }
    }

}
