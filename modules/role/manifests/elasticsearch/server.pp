# = Class: role::elasticsearch::server
#
# This class sets up Elasticsearch in a WMF-specific way.
#
class role::elasticsearch::server{

    if ($::realm == 'production' and hiera('elasticsearch::rack', undef) == undef) {
        fail("Don't know rack for ${::hostname} and rack awareness should be turned on")
    }

    if ($::realm == 'labs' and hiera('elasticsearch::cluster_name', undef) == undef) {
        $msg = '\$::elasticsearch::cluster_name must be set to something unique to the labs project.'
        $msg2 = 'You can set it in the hiera config of the project'
        fail("${msg}\n${msg2}")
    }

    if hiera('has_lvs', true) {
        include lvs::realserver
    }

    ferm::service { 'elastic-http':
        proto   => 'tcp',
        port    => '9200',
        notrack => true,
        srange  => '(($INTERNAL @resolve(wikitech.wikimedia.org) @resolve(labtestwikitech.wikimedia.org)))',
    }

    ferm::service { 'elastic-https':
        proto   => 'tcp',
        port    => '9243',
        notrack => true,
        srange  => '$INTERNAL',
    }

    $elastic_nodes = hiera('elasticsearch::cluster_hosts')
    $elastic_nodes_ferm = join($elastic_nodes, ' ')

    ferm::service { 'elastic-inter-node':
        proto   => 'tcp',
        port    => '9300',
        notrack => true,
        srange  => "@resolve((${elastic_nodes_ferm}))",
    }

    # TODO: remove this ferm::service once multicast discovery is disabled.
    ferm::service { 'elastic-zen-discovery':
        proto  => 'udp',
        port   => '54328',
        srange => '$INTERNAL',
    }

    system::role { 'role::elasticsearch::server':
        ensure      => 'present',
        description => 'elasticsearch server',
    }

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    # Install
    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }

    include ::standard
    if $::standard::has_ganglia {
        include ::elasticsearch::ganglia
    }

    $site_name = hiera('elasticsearch::https::certificate_name', $::fqdn)

    class { '::nginx::simple_tlsproxy':
        site_name    => $site_name,
        backend_port => 9200,
        port         => 9243,
    }

    # TODO: cleanup of previous nginx configuration file should be removed once
    #       this change has been deployed on all elastic nodes
    file { [
        '/etc/nginx/sites-available/elasticsearch-ssl-termination',
        '/etc/nginx/sites-enabled/elasticsearch-ssl-termination',
    ]:
        ensure => absent,
    }

    ::monitoring::service { 'elasticsearch-https':
        description   => 'Elasticsearch HTTPS',
        check_command => "check_ssl_http_on_port!${site_name}!9243",
    }

    include elasticsearch::monitor::diamond
    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check

    file { '/etc/elasticsearch/scripts':
        ensure  => absent,
    }

    file { '/etc/elasticsearch/scripts/mwgrep.groovy':
        ensure => absent
    }
}
