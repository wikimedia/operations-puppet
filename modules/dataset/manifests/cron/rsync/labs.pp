class dataset::cron::rsync::labs($enable=true) {
    include role::mirror::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # this will change shortly to a separate stanza for eqiad
    if ($::site == 'pmtpa' or $::site == 'eqiad') {
        include gluster::client

        system::role { 'dataset::cron::rsync::labs':
            ensure      => $ensure,
            description => 'rsyncer of dumps to labs gluster fs'
        }

        mount { '/mnt/glusterpublicdata':
            ensure  => 'mounted',
            device  => 'labstore1.pmtpa.wmnet:/publicdata-project',
            fstype  => 'glusterfs',
            options => 'defaults,_netdev=bond0,log-level=WARNING,log-file=/var/log/gluster.log',
            require => Package['glusterfs-client'],
        }

        file { '/usr/local/bin/wmfdumpsmirror.py':
            ensure => 'present',
            mode   => '0755',
            source => 'puppet:///modules/dataset/gluster/wmfdumpsmirror.py',
        }

        file{ '/usr/local/sbin/gluster-rsync-cron.sh':
            ensure => 'present',
            mode   => '0755',
            source => 'puppet:///modules/dataset/gluster/gluster-rsync-cron.sh',
        }

        cron { 'dumps_gluster_rsync':
            ensure      => $ensure,
            user        => 'root',
            minute      => '50',
            hour        => '3',
            command     => '/usr/local/sbin/gluster-rsync-cron.sh',
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            require     => [File['/usr/local/bin/wmfdumpsmirror.py'],
                           File['/usr/local/sbin/gluster-rsync-cron.sh'],
                           Mount['/mnt/glusterpublicdata']],
        }
    }
}
