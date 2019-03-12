# = Class: elasticsearch
#
# This class installs/configures/manages the elasticsearch service.
#
# == Parameters:
# - $default_instance_params: Parameter overrides for ::elasticsearch::instance
# - $java_package: Name of package containing appropriate JDK. Default: openjdk-8-jdk.
# - $version: Version of elasticsearch to configure. Either 5 or 6. Default: 5.
# - $logstash_host: Host to send logs to
# - $logstash_gelf_port: Tcp port on $logstash_host to send gelf formatted logs to.
#
# == Sample usage:
#
#   class { 'elasticsearch':
#       default_instance_params => {
#           cluster_name => 'labs-search',
#       }
#   }
#
class elasticsearch (
    Optional[Hash[String, Elasticsearch::InstanceParams]] $instances = undef,
    Elasticsearch::InstanceParams $default_instance_params           = {},
    String $java_package                                             = 'openjdk-8-jdk',
    Enum['5', '6'] $version                                          = '5',
    Stdlib::Absolutepath $base_data_dir                              = '/srv/elasticsearch',
    Optional[String] $logstash_host                                  = undef,
    Optional[Wmflib::IpPort] $logstash_gelf_port                     = 12201,
    Optional[String] $rack                                           = undef,
    Optional[String] $row                                            = undef,
) {
    # Check arguments and set package
    case $version {
        '5': {
            $package_name = 'elasticsearch'
        }
        '6': {
            $package_name = 'elasticsearch-oss'
        }
        default: { fail("Unsupported elasticsearch version: ${version}") }
    }

    if empty($instances) {
        $cluster_name = $default_instance_params['cluster_name']
        $defaults_for_single_instance = {
            http_port          => 9200,
            transport_tcp_port => 9300,
        }
        $configured_instances = {
            $cluster_name => merge(
                $defaults_for_single_instance,
                $default_instance_params
            )
        }
    } else {
        $configured_instances = $instances.reduce({}) |$agg, $kv_pair| {
            $instance_params = merge($default_instance_params, $kv_pair[1])
            $cluster_name = $instance_params['cluster_name']

            $agg + [$cluster_name, $instance_params]
        }
    }

    class { '::elasticsearch::packages':
        java_package          => $java_package,
        package_name          => $package_name,
        # Hack to be resolved in followup patch
        send_logs_to_logstash => $configured_instances.reduce(false) |Boolean $agg, $kv_pair| {
            $agg or pick_default($kv_pair[1]['send_logs_to_logstash'], true)
        }
    }

    class { '::elasticsearch::curator': }

    # Overwrite default env file provided by elastic
    # so that it does not conflict without our var set by systemd unit
    $ensure_etc_default = $version ? {
        '5' => 'absent',
        '6' => 'file',
    }
    file { '/etc/default/elasticsearch':
        ensure  => $ensure_etc_default,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => file('elasticsearch/elasticsearch.env'),
        require => Package['elasticsearch']
    }

    # main elasticsearch dir, purge it to ensure any undefined config file is removed
    file { '/etc/elasticsearch':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
    }

    # These files are created when the server is using the default cluster_name
    # and are never written to when the server is using the correct cluster name
    # thus leaving old files with no useful information named in such a way that
    # someone might think they contain useful logs.
    file { '/var/log/elasticsearch/elasticsearch.log':
        ensure => absent,
    }
    file { '/var/log/elasticsearch/elasticsearch_index_indexing_slowlog.log':
        ensure => absent,
    }
    file { '/var/log/elasticsearch/elasticsearch_index_search_slowlog.log':
        ensure => absent,
    }

    file { $base_data_dir:
        ensure => directory,
        owner  => 'elasticsearch',
        group  => 'elasticsearch',
        mode   => '0755',
    }

    logrotate::rule { 'elasticsearch':
        ensure        => present,
        file_glob     => '/var/log/elasticsearch/*.log',
        frequency     => 'daily',
        copy_truncate => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 7,
        compress      => true,
    }

    # since we are using our own systemd unit, ensure that the service
    # installed by the debian package is disabled
    service { 'elasticsearch':
        ensure  => stopped,
        enable  => false,
        require => Package['elasticsearch'],
    }

    systemd::unit { "elasticsearch_${version}@.service":
        ensure  => present,
        content => systemd_template("elasticsearch_${version}@"),
    }

    $configured_instances.each |$instance_title, $instance_params| {
        elasticsearch::instance { $instance_title:
            version            => $version,
            base_data_dir      => $base_data_dir,
            logstash_host      => $logstash_host,
            logstash_gelf_port => $logstash_gelf_port,
            rack               => $rack,
            row                => $row,
            *                  => $instance_params
        }
    }

    # Cluster management tool
    file { '/usr/local/bin/es-tool':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/elasticsearch/es-tool',
        require => [Package['python-elasticsearch'], Package['python-ipaddr']],
    }

    $services_names = $configured_instances.map |$instance_title, $instance_params| {
        "elasticsearch_${version}@${instance_params['cluster_name']}"
    }

    file { '/etc/elasticsearch/instances':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => join($services_names, "\n"),
    }

}
