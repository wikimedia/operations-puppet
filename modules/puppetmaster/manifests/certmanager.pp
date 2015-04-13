class puppetmaster::certmanager {
    user { 'certmanager':
        home       => '/var/lib/puppet',
        managehome => false,
        system     => true,
    }

    # Allow remote execution for cert cleanup
    ssh::userkey { 'certmanager.pub':
        source => 'puppet:///modules/openstack/puppet_cert_manager.pub',
        user   => 'certmanager',
    }

    sudo::user { 'certmanager':
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/puppet cert clean *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-key -d *'
        ]
    }
}
