class profile::openstack::base::puppetmaster::common(
    Array[Stdlib::Host] $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
) {
    include profile::openstack::base::puppetmaster::enc_client

    # Update Puppet git repositories
    class { 'puppetmaster::gitsync':
        run_every_minutes => 1,
    }

    ferm::service { 'puppetmaster':
        proto  => 'tcp',
        port   => '8141',
        srange => "(\$LABS_NETWORKS @resolve((${labweb_hosts.join(' ')})))",
    }
}
