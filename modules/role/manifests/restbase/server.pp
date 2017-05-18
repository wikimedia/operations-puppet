# == Class role::restbase
# Config should be pulled from hiera
#
# filtertags: labs-project-deployment-prep
class role::restbase::server {
    system::role { 'restbase': description => "Restbase ${::realm}" }
    warning('This role is deprecated; please use role::restbase::base or equivalent.')
    include ::passwords::cassandra
    include ::base::firewall
    include ::standard

    include ::restbase
    include ::restbase::monitoring

    if hiera('has_lvs', true) {
        include role::lvs::realserver
    }

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
