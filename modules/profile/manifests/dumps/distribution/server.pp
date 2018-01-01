# Profile for Dumps distribution server in the Public VLAN,
# that serves dumps to Cloud VPS/Stat boxes via NFS,
# or via web or rsync to mirrors

class profile::dumps::distribution::server {
    class { '::dumpsuser': }

    file { '/srv/dumps':
        ensure => 'directory',
    }

    mount { '/srv/dumps':
        ensure  => mounted,
        fstype  => ext4,
        options => 'defaults,noatime',
        atboot  => true,
        device  => '/dev/data/dumps',
        require => File['/srv/dumps'],
    }

    file {'/srv/dumps/xmldatadumps':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
