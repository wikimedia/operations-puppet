class role::labs::tools::proxy {
    include toollabs::proxy
    include role::toollabs::k8s::webproxy

    ferm::service { 'proxymanager':
        proto  => 'tcp',
        port   => '8081',
        desc   => 'Proxymanager service for Labs instances',
        srange => '$INTERNAL',
    }

    ferm::service{ 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }

    ferm::service{ 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }

    system::role { 'role::labs::tools::proxy': description => 'Tool labs generic web proxy' }
}
