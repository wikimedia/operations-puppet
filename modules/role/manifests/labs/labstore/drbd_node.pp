# Role class for a DRBD client
# This will be moved elsewhere
class role::labs::labstore::drbd_node {

    include labstore::drbd_node

    labstore::drbd_resource {'maps':
        nodes  => [
                  'labstore-test-01.testlabs.eqiad.wmflabs',
                  'labstore-test-02.testlabs.eqiad.wmflabs'
                  ],
        port   => 7788,
        device => '/dev/drbd1',
        disk   => '/dev/misc/maps',
        notify => Exec['drbdadm-adjust'],
    }

    labstore::drbd_resource {'tools-project':
        nodes  => [
                  'labstore-test-01.testlabs.eqiad.wmflabs',
                  'labstore-test-02.testlabs.eqiad.wmflabs'
                  ],
        port   => 7789,
        device => '/dev/drbd2',
        disk   => '/dev/tools-project/tools-project',
        notify => Exec['drbdadm-adjust'],
    }

    labstore::drbd_resource {'others':
        nodes  => [
                  'labstore-test-01.testlabs.eqiad.wmflabs',
                  'labstore-test-02.testlabs.eqiad.wmflabs'
                  ],
        port   => 7790,
        device => '/dev/drbd3',
        disk   => '/dev/misc/others',
        notify => Exec['drbdadm-adjust'],
    }

    # Ensure that the service is running
    base::service_unit { 'drbd':
        ensure         => present,
        service_params => {
            hasrestart => true,
            hasstatus  => true,
            path       => '/etc/init.d',
        }
    }

    # When new resources are defined, this exec
    exec { 'drbdadm-adjust':
        command     => '/sbin/drbdadm adjust all',
        refreshonly => true,
    }

}
