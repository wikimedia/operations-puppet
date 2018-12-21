#
# This class configures elasticsearch
#
# == Parameters:
# - $dc_settings: data center specific overrides for ::elasticsearch::instance
# - $common_settings: global overrides for ::elasticsearch::instance
# - $logstash_host: Host to send logs to
# - $logstash_gelf_port: Tcp port on $logstash_host to send gelf formatted logs to.
# - $rack: Rack server is in. Used for allocation awareness.
# - $row: Row server is in. Used for allocation awareness.
#
#
class profile::elasticsearch(
    Hash[String, Elasticsearch::InstanceParams] $instances = hiera('profile::elasticsearch::instances'),
    Elasticsearch::InstanceParams $dc_settings = hiera('profile::elasticsearch::dc_settings'),
    Elasticsearch::InstanceParams $common_settings = hiera('profile::elasticsearch::common_settings'),
    Stdlib::AbsolutePath $base_data_dir = hiera('profile::elasticsearch::base_data_dir'),

    String $logstash_host = hiera('logstash_host'),
    Wmflib::IpPort $logstash_gelf_port = hiera('logstash_gelf_port'),
    String $rack = hiera('profile::elasticsearch::rack'),
    String $row = hiera('profile::elasticsearch::row'),
) {
    # Rather than asking hiera to magically merge these settings for us, we
    # explicitly take two sets of defaults for global defaults and per-dc
    # defaults. Per cluster overrides are then provided in $instances.
    $settings = $common_settings + $dc_settings

    # Sane defaults to simplify single instance configuration
    $defaults_for_single_instance = {
        http_port          => 9200,
        transport_tcp_port => 9300,
    }

    # Resolve instance configuration here, rather than in the elasticsearch
    # define, so we have access to final configuration, such as http ports,
    # for configuring firewalls and such.
    # Also accessed from profile::elasticsearch::* for firewalls, proxies, etc.
    $configured_instances = empty($instances) ? {
        true    => {
            'default' => $defaults_for_single_instance + $settings,
        },
        default => $instances.reduce({}) |$agg, $kv_pair| {
            $instance_title = $kv_pair[0]
            $instance_params = $kv_pair[1]
            $final_params = $settings + $instance_params
            $agg + [$instance_title, $final_params]
        }
    }

    # Get all unique elastic nodes across all instances.
    # This is needed to set ferm rules for cross cluster communication
    $all_elastic_nodes = unique($configured_instances.reduce([]) |$result, $instance_params| {
        $result + $instance_params[1]['cluster_hosts']
    })

    # filter out instances that should not be deployed on this node
    # this is used for the cirrus clusters, where multiple sub clusters are defined
    # on a subset of all nodes.
    #
    # note in filter |$instance| below, $instance is an array [ key, value ]
    # see https://puppet.com/docs/puppet/5.5/function.html#filter for details
    $filtered_instances = $configured_instances.filter |$instance| { $facts['fqdn'] in $instance[1]['cluster_hosts'] }

    # Accessed from profile::elasticsearch::* for firewalls, proxies, etc.
    $filtered_instances.each |$instance_title, $instance_params| {
        $transport_tcp_port = pick_default($instance_params['transport_tcp_port'], 9300)
        $elastic_nodes_ferm = join(pick_default($all_elastic_nodes, [$::fqdn]), ' ')

        ferm::service { "elastic-inter-node-${transport_tcp_port}":
            proto   => 'tcp',
            port    => $transport_tcp_port,
            notrack => true,
            srange  => "@resolve((${elastic_nodes_ferm}))",
        }
    }

    apt::repository { 'wikimedia-elastic':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'component/elastic55 thirdparty/elastic55',
        before     => Class['::elasticsearch'],
    }

    # ensure that apt is refreshed before installing elasticsearch
    Exec['apt-get update'] -> Class['::elasticsearch']

    # Install
    class { '::elasticsearch':
        version            => 5,
        instances          => $filtered_instances,
        base_data_dir      => $base_data_dir,
        logstash_host      => $logstash_host,
        logstash_gelf_port => $logstash_gelf_port,
        rack               => $rack,
        row                => $row,
    }
}
