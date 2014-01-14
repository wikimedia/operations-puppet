class download::gluster {
    include role::mirror::common
    include gluster::client

    system::role { 'download::gluster': description => 'Gluster dumps copy' }

    mount { '/mnt/glusterpublicdata':
        ensure  => mounted,
        device  => 'labstore1.pmtpa.wmnet:/publicdata-project',
        fstype  => 'glusterfs',
        options => 'defaults,_netdev=bond0,log-level=WARNING,log-file=/var/log/gluster.log',
        require => Package['glusterfs-client'],
    }

    file { '/usr/local/bin/wmfdumpsmirror.py':
        ensure => present,
        mode   => '0755',
        source => 'puppet:///modules/download/gluster/wmfdumpsmirror.py',
    }

    file{ '/usr/local/sbin/gluster-rsync-cron.sh':
        ensure => present,
        mode   => '0755',
        source => 'puppet:///modules/download/gluster/gluster-rsync-cron.sh',
    }

    cron { 'dumps_gluster_rsync':
        ensure      => present,
        user        => 'root',
        minute      => '50',
        hour        => '3',
        command     => '/usr/local/sbin/gluster-rsync-cron.sh',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        require     => [ File[['/usr/local/bin/wmfdumpsmirror.py','/usr/local/sbin/gluster-rsync-cron.sh'] ],Mount['/mnt/glusterpublicdata'] ],
    }
}
