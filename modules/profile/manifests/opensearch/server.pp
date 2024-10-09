# SPDX-License-Identifier: Apache-2.0
#
# This class configures OpenSearch
#
# == Parameters:
# - $dc_settings: data center specific overrides for ::opensearch::instance
# - $common_settings: global overrides for ::opensearch::instance
# - $logstash_host: Host to send logs to
# - $logstash_logback_port: Tcp port on localhost to send structured logs to.
# - $logstash_transport: Transport mechanism for logs.
# - $rack: Rack server is in. Used for allocation awareness.
# - $row: Row server is in. Used for allocation awareness.
# - $version: version of the package to install
# - $java_home: optionally specify the JAVA_HOME path in the opensearch systemd unit.
# - $enable_curator: installs curator.  default false
#
class profile::opensearch::server(
    Hash[String, Opensearch::InstanceParams] $instances             = lookup('profile::opensearch::instances'),
    Opensearch::InstanceParams               $dc_settings           = lookup('profile::opensearch::dc_settings'),
    Opensearch::InstanceParams               $common_settings       = lookup('profile::opensearch::common_settings'),
    Stdlib::AbsolutePath                     $base_data_dir         = lookup('profile::opensearch::base_data_dir'),
    String                                   $logstash_host         = lookup('logstash_host'),
    Stdlib::Port                             $logstash_logback_port = lookup('logstash_logback_port'),
    String                                   $rack                  = lookup('profile::opensearch::rack'),
    String                                   $row                   = lookup('profile::opensearch::row'),
    Enum['1.0.0', '2.0.0']                   $version               = lookup('profile::opensearch::version',            { 'default_value' => '1.0.0' }),
    Optional[String]                         $java_home             = lookup('profile::opensearch::java_home',          { 'default_value' => undef }),
    Boolean                                  $enable_curator        = lookup('profile::opensearch::curator::enable',    { 'default_value' => false }),
) {

    require ::profile::java

    # Rather than asking hiera to magically merge these settings for us, we
    # explicitly take two sets of defaults for global defaults and per-dc
    # defaults. Per cluster overrides are then provided in $instances.
    $settings = $common_settings + $dc_settings

    # Sane defaults to simplify single instance configuration
    $defaults_for_single_instance = {
        http_port          => 9200,
        transport_tcp_port => 9300,
    }

    # Resolve instance configuration here, rather than in the opensearch
    # define, so we have access to final configuration, such as http ports,
    # for configuring firewalls and such.
    # Also accessed from profile::opensearch::* for firewalls, proxies, etc.
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

    # Get all unique opensearch nodes across all instances.
    # This is needed to set ferm rules for cross cluster communication
    $all_opensearch_nodes = unique($configured_instances.reduce([]) |$result, $instance_params| {
        $result + $instance_params[1]['cluster_hosts']
    })

    # filter out instances that should not be deployed on this node
    # this is used for the cirrus clusters, where multiple sub clusters are defined
    # on a subset of all nodes.
    #
    # note in filter |$instance| below, $instance is an array [ key, value ]
    # see https://puppet.com/docs/puppet/5.5/function.html#filter for details
    $filtered_instances = $configured_instances.filter |$instance| { $facts['fqdn'] in $instance[1]['cluster_hosts'] }

    # Accessed from profile::opensearch::* for firewalls, proxies, etc.
    $filtered_instances.each |$instance_title, $instance_params| {
        $transport_tcp_port = pick_default($instance_params['transport_tcp_port'], 9300)
        $opensearch_nodes_ferm = join(pick_default($all_opensearch_nodes, [$::fqdn]), ' ')

        ferm::service { "opensearch-inter-node-${transport_tcp_port}":
            proto   => 'tcp',
            port    => $transport_tcp_port,
            notrack => true,
            srange  => "@resolve((${opensearch_nodes_ferm}))",
        }
    }

    $major_version = split($version, '[.]')[0]
    $apt_component = "opensearch${major_version}"

    apt::repository { 'wikimedia-opensearch':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/${apt_component}",
        before     => Class['::opensearch'],
    }

    # Originally added as part of T265113 - userland util to interact with kernel EDAC drivers
    package { 'edac-utils':
        ensure => latest,
    }

    # ensure that apt is refreshed before installing opensearch
    Exec['apt-get update'] -> Class['::opensearch']

    # Install
    class { '::opensearch':
        version               => $major_version,
        instances             => $filtered_instances,
        base_data_dir         => $base_data_dir,
        logstash_host         => $logstash_host,
        logstash_logback_port => $logstash_logback_port,
        rack                  => $rack,
        row                   => $row,
        java_home             => pick($java_home, $profile::java::default_java_home),
        enable_curator        => $enable_curator,
    } -> file { '/usr/share/opensearch/plugins':
        ensure => 'directory',
        force  => true,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # TODO: use fork when available
    $::profile::opensearch::server::configured_instances.reduce(9108) |$prometheus_port, $kv_pair| {
        $cluster_name = $kv_pair[0]
        $cluster_params = $kv_pair[1]
        $http_port = $cluster_params['http_port']

        profile::prometheus::elasticsearch_exporter { "${::hostname}:${http_port}":
            prometheus_port    => $prometheus_port,
            elasticsearch_port => $http_port,
        }
        $prometheus_port + 1
    }
}
