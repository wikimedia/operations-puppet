# Base class to set up a Public Dumps server
class public_dumps::server {

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

}
