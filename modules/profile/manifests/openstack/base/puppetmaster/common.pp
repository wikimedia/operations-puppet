class profile::openstack::base::puppetmaster::common () {
    include profile::openstack::base::puppetmaster::enc_client

    # Update Puppet git repositories
    class { 'puppetmaster::gitsync':
        run_every_minutes => 1,
    }

    ferm::service { 'puppetmaster':
        proto  => 'tcp',
        port   => '8141',
        srange => '$LABS_NETWORKS',
    }

    # purge the enc server, now on separate servers
    class { [ 'nginx', 'uwsgi' ]:
        ensure => absent,
    }

    class { '::openstack::puppet::master::encapi':
        ensure                => absent,
        mysql_host            => 'does-not-exist.example.com',
        mysql_db              => 'just-for-validation',
        mysql_username        => 'just-for-validation',
        mysql_password        => 'just-for-validation',
        labweb_hosts          => [],
        openstack_controllers => [],
        designate_hosts       => [],
        labs_instance_ranges  => [],
    }
}
