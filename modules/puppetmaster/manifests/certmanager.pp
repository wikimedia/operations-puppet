class puppetmaster::certmanager(
    $remote_cert_cleaners=[]
){
    user { 'certmanager':
        home   => '/',
        system => true,
    }

    # Allow remote execution for cert cleanup
    ssh::userkey { 'certmanager.pub':
        content => template('puppetmaster/puppet_cert_manager.pub.erb'),
        user    => 'certmanager',
    }

    sudo::user { 'certmanager':
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/puppet cert clean *',
        ],
    }

    $remote_cert_cleaners_spaced = join($remote_cert_cleaners, ' ')
    security::access::config { 'certmanager':
        content  => "+ : certmanager : ${remote_cert_cleaners_spaced}\n",
        priority => 60,
    }
}
