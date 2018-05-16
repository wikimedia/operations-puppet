# filtertags: labs-project-tools
class role::toollabs::proxy {

    include ::toollabs::base
    include ::toollabs::proxy
    include ::profile::toolforge::toolviews
    include ::role::toollabs::k8s::webproxy
    include ::profile::base::firewall
    include ::toollabs::ferm_handlers

    ferm::service { 'proxymanager':
        proto  => 'tcp',
        port   => '8081',
        desc   => 'Proxymanager service for Labs instances',
        srange => '$LABS_NETWORKS',
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

    system::role { 'toollabs::proxy':
        description => 'Tool labs generic web proxy'
    }
}
