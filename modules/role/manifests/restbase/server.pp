# == Class role::restbase
# Config should be pulled from hiera
class role::restbase::server {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::passwords::cassandra
    include base::firewall

    include ::restbase
    include ::restbase::monitoring

    include lvs::realserver

    # Add conftool scripts and credentials
    include ::conftool::scripts

    # RESTBase rate limiting DHT firewall rule
    $rb_hosts_ferm = join(hiera('restbase::hosts'), ' ')
    ferm::service { 'restbase-ratelimit':
        proto  => 'tcp',
        port   => '3050',
        srange => "@resolve((${rb_hosts_ferm}))",
    }

    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

}
