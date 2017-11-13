# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::analytics {
    system::role { 'prometheus::analytics':
        description => 'Prometheus server (analytics)',
    }

    include ::standard
    include ::base::firewall

    $targets_path = '/srv/prometheus/analytics/targets'
    $storage_retention = hiera('prometheus::server::storage_retention', '2190h0m0s')
    $max_chunks_to_persist = hiera('prometheus::server::max_chunks_to_persist', '524288')
    $memory_chunks = hiera('prometheus::server::memory_chunks', '1048576')

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
        },
    }

    $jmx_exporter_jobs = [
      {
        'job_name'        => 'jmx_druid',
        'scrape_timeout'  => '25s',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_druid_*.yaml" ]}
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "druid_broker_${::site}":
        dest       => "${targets_path}/jmx_druid_broker_${::site}.yaml",
        class_name => 'profile::druid::broker',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "druid_overlord_${::site}":
        dest       => "${targets_path}/jmx_druid_overlord_${::site}.yaml",
        class_name => 'profile::druid::overlord',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "druid_middlemanager_${::site}":
        dest       => "${targets_path}/jmx_druid_middlemanager_${::site}.yaml",
        class_name => 'profile::druid::middlemanager',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "druid_coordinator_${::site}":
        dest       => "${targets_path}/jmx_druid_coordinator_${::site}.yaml",
        class_name => 'profile::druid::coordinator',
        site       => $::site,
    }

    prometheus::jmx_exporter_config{ "druid_historical_${::site}":
        dest       => "${targets_path}/jmx_druid_historical_${::site}.yaml",
        class_name => 'profile::druid::historical',
        site       => $::site,
    }

    prometheus::server { 'analytics':
        storage_encoding      => '2',
        listen_address        => '127.0.0.1:9905',
        storage_retention     => $storage_retention,
        max_chunks_to_persist => $max_chunks_to_persist,
        memory_chunks         => $memory_chunks,
        global_config_extra   => $config_extra,
        scrape_configs_extra  => array_concat($jmx_exporter_jobs)
    }

    prometheus::web { 'analytics':
        proxy_pass => 'http://localhost:9905/analytics',
    }

    prometheus::rule { 'rules_analytics.conf':
        instance => 'analytics',
        source   => 'puppet:///modules/role/prometheus/rules_analytics.conf',
    }
}
