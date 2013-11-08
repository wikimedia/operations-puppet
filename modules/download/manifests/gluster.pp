class download::gluster {

    include role::mirror::common
    include gluster::client

    system::role { 'download::gluster': description => 'Gluster dumps copy' }

    file { '/mnt/glusterpublicdata':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775';
    }

    mount {
        '/mnt/glusterpublicdata':
            ensure  => present,
            device  => 'labstore1.pmtpa.wmnet:/publicdata-project',
            fstype  => 'glusterfs',
            options => 'defaults,_netdev=bond0,log-level=WARNING,log-file=/var/log/gluster.log',
            require => [Package['glusterfs-client'], File['/mnt/glusterpublicdata']];
    }

    file {
        '/usr/local/bin/wmfdumpsmirror.py':
            ensure => present,
            mode   => '0755',
            source => 'puppet:///files/mirror/wmfdumpsmirror.py';
        '/usr/local/sbin/gluster-rsync-cron.sh':
            ensure => present,
            mode   => '0755',
            source => 'puppet:///files/mirror/gluster-rsync-cron.sh',
    }

    cron { 'dumps_gluster_rsync':
        ensure      => present,
        user        => root,
        minute      => '50',
        hour        => '3',
        command     => '/usr/local/sbin/gluster-rsync-cron.sh',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        require     => [ File[ ['/usr/local/bin/wmfdumpsmirror.py','/usr/local/sbin/gluster-rsync-cron.sh'],['/mnt/glusterpublicdata'] ]];
    }
}

