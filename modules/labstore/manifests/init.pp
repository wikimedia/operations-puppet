# == class labstore
#
# This class configures the server as an NFS kernel server
# and sets the general configuration for that service, without
# actually exporting any filesystems
#

class labstore {

    require_package('nfs-kernel-server')

    file { '/usr/local/sbin/set-stripe-cache':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/set-stripe-cache',
    }

    # This is done unconditionally to all the md devices at
    # interval to guard against (a) puppet not applying for
    # any reason, and (b) the fact that the set of started
    # md devices on a labstore* is ultimately variable and
    # dynamic depending on its current role.
    #
    cron { 'set-stripe-caches':
        command => '/usr/local/sbin/set-stripe-cache 4096',
        user    => 'root',
        minute  => '*/5',
        require => File['/usr/local/sbin/set-stripe-cache'],
    }

    # Labstores need to be able to scp from one server
    # to the other (in order to do backups)

    ssh::userkey { 'root-labstore':
        ensure => present,
        user   => 'root',
        skey   => 'labstore',
        source => 'puppet:///modules/labstore/id_labstore.pub',
    }

    file { '/root/.ssh/id_labstore':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => secret('labstore/id_labstore'),
    }

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-kernel-server',
    }

}

