class puppetmaster::certssh {
    # Allow remote execution for cert cleanup
    ssh::userkey { 'puppet_certs.pub':
        source => 'puppet:///modules/openstack/puppet_certs.pub'
    }
}

