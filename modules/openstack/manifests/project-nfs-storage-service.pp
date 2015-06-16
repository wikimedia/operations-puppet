class openstack::project-nfs-storage-service {

    file { '/etc/init/manage-nfs-volumes.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/openstack/manage-nfs-volumes.conf',
    }

    file { '/usr/local/sbin/start-nfs':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        source  => 'puppet:///modules/openstack/start-nfs',
    }

    file { '/usr/local/sbin/set-stripe-cache':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/openstack/set-stripe-cache',
    }

    file { '/etc/default/nfs-common':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/openstack/nfs-common',
    }

    file { '/etc/default/nfs-kernel-server':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/openstack/nfs-kernel-server',
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

    $sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
            'ALL = NOPASSWD: /bin/rmdir /srv/*',
            'ALL = NOPASSWD: /usr/local/sbin/sync-exports' ]
    sudo::user { [ 'nfsmanager' ]: privileges => $sudo_privs, require => User['nfsmanager'] }

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

    file { '/etc/exports.d/ROOT.exports':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/openstack/ROOT.exports',
    }

    file { '/etc/exports.d/PUBLIC.exports':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/openstack/PUBLIC.exports',
    }

    if ($::site == 'eqiad') {
        cron { 'Update labs ssh keys':
                ensure  => present,
                user    => 'root',
                command => '/usr/local/sbin/manage-keys-nfs --logfile=/var/log/manage-keys.log >/dev/null 2>&1',
                hour    => '*',
                minute  => '*/5',
        }
    }
}
