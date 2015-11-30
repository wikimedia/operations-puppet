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
        proto => 'tcp',
        port  => '9200',
        notrack => true,
        srange => '(($INTERNAL @resolve(silver.wikimedia.org)))',
    }

    $elastic_nodes = hiera('elasticsearch::cluster_hosts')
    $elastic_nodes_ferm = join($elastic_nodes, ' ')

    ferm::service { 'elastic-inter-node':
        proto => 'tcp',
        port  => '9300',
        notrack => true,
        srange  => "@resolve((${elastic_nodes_ferm}))",
    }

    ferm::service { 'elastic-zen-discovery':
        proto => 'udp',
        port  => '54328',
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

    if $::standard::has_ganglia {
        include ::elasticsearch::ganglia
    }

    include elasticsearch::monitor::diamond
    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check

    file { '/etc/elasticsearch/scripts':
        ensure => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['elasticsearch'],
    }

    file { '/etc/elasticsearch/scripts/mwgrep.groovy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => '_source["text"].contains(query)',
        mode    => '0444',
        require => Package['elasticsearch'],
    }
}
