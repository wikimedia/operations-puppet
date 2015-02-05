class openstack::project-nfs-storage-service {
    file { '/etc/init/manage-nfs-volumes.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/openstack/manage-nfs-volumes.conf',
        before  => Service['manage-nfs-volumes'],
        notify  => Service['manage-nfs-volumes'],
    }

    service { 'manage-nfs-volumes':
        ensure  => running,
    }

    nrpe::monitor_service { 'manage-nfs-volumes':
        description  => 'manage_nfs_volumes_running',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/bin/python /usr/local/sbin/manage-nfs-volumes'"
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
