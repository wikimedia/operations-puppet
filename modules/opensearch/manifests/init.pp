# SPDX-License-Identifier: Apache-2.0
# = Class: opensearch
#
# This class installs/configures/manages the opensearch service.
#
# == Parameters:
# - $default_instance_params: Parameter overrides for ::opensearch::instance
# - $version: Version of opensearch to configure. Either 1 or 2. Default: 1.
# - $logstash_host: Host to send logs to
# - $logstash_logback_port: Tcp port on localhost to send structured logs to.
# - $logstash_transport: Transport mechanism for logs.
#
# == Sample usage:
#
#   class { 'opensearch':
#       default_instance_params => {
#           cluster_name => 'labs-search',
#       }
#   }
#
class opensearch (
    Optional[Hash[String, Opensearch::InstanceParams]] $instances               = undef,
    Opensearch::InstanceParams                         $default_instance_params = {},
    Enum['1', '2']                                     $version                 = '1',
    Stdlib::Absolutepath                               $base_data_dir           = '/srv/opensearch',
    Optional[String]                                   $logstash_host           = undef,
    Optional[Stdlib::Port]                             $logstash_logback_port   = 11514,
    Optional[String]                                   $rack                    = undef,
    Optional[String]                                   $row                     = undef,
    Optional[String]                                   $java_home               = undef,
    Boolean                                            $enable_curator          = false,
) {
    # Check arguments and set package
    case $version {
        '1': { $package_name = 'opensearch' }
        '2': { $package_name = 'opensearch' }
        default: { fail("Unsupported opensearch version: ${version}") }
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

    class { '::opensearch::packages':
        package_name          => $package_name,
        # Hack to be resolved in followup patch
        send_logs_to_logstash => $configured_instances.reduce(false) |Boolean $agg, $kv_pair| {
            $agg or pick_default($kv_pair[1]['send_logs_to_logstash'], true)
        }
    }

    if ($enable_curator) {
        class { '::opensearch::curator': }
    }

    # Overwrite default env file provided by opensearch
    # so that it does not conflict without our var set by systemd unit
    file { '/etc/default/opensearch':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => file('opensearch/opensearch.env'),
        require => Package['opensearch']
    }

    # main opensearch dir, purge it to ensure any undefined config file is removed
    file { '/etc/opensearch':
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
    file { '/var/log/opensearch/opensearch.log':
        ensure => absent,
    }
    file { '/var/log/opensearch/opensearch_index_indexing_slowlog.log':
        ensure => absent,
    }
    file { '/var/log/opensearch/opensearch_index_search_slowlog.log':
        ensure => absent,
    }

    file { [ $base_data_dir, '/var/log/opensearch' ]:
        ensure  => directory,
        owner   => 'opensearch',
        group   => 'opensearch',
        mode    => '0755',
        require => Package['opensearch'],
    }

    logrotate::rule { 'opensearch':
        ensure        => present,
        file_glob     => '/var/log/opensearch/*.log',
        frequency     => 'daily',
        copy_truncate => true,
        missing_ok    => true,
        not_if_empty  => true,
        rotate        => 7,
        compress      => true,
    }

    # since we are using our own systemd unit, ensure that the service
    # installed by the debian package is disabled
    service { 'opensearch':
        ensure  => stopped,
        enable  => false,
        require => Package['opensearch'],
    }

    systemd::unit { "opensearch_${version}@.service":
        ensure  => present,
        content => systemd_template("opensearch_${version}@"),
    }

    $configured_instances.each |$instance_title, $instance_params| {
        opensearch::instance { $instance_title:
            version               => $version,
            base_data_dir         => $base_data_dir,
            logstash_host         => $logstash_host,
            logstash_logback_port => $logstash_logback_port,
            rack                  => $rack,
            row                   => $row,
            *                     => $instance_params
        }
    }

    $services_names = $configured_instances.map |$instance_title, $instance_params| {
        "opensearch_${version}@${instance_params['cluster_name']}"
    }

    file { '/etc/opensearch/instances':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => join($services_names, "\n"),
    }

}
