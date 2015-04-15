class puppetmaster::certmanager(
    $remote_cert_cleaner=""
){
    user { 'certmanager':
        home       => '/home/certmanager',
        managehome => true,
        system     => true,
    }

    # Allow remote execution for cert cleanup
    ssh::userkey { 'certmanager.pub':
        content => template('puppetmaster/puppet_cert_manager.pub.erb'),
        user    => 'certmanager',
    }

    sudo::user { 'certmanager':
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/puppet cert clean *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-key -d *'
        ]
    }
}
