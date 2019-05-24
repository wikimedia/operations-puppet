# = Define: icinga::monitor::elasticsearch::cirrus_settings_check
define icinga::monitor::elasticsearch::cirrus_settings_check(
    Stdlib::Port $port,
    Hash[String, Elasticsearch::InstanceParams] $settings,
    Boolean $enable_remote_search,
) {
    require ::icinga::elasticsearch::cirrus_settings_plugin

    if $enable_remote_search {
        $remote_clusters = $settings.filter |$instance| { $instance[1]['cluster_name'] != $title }
        $extracted_settings = $remote_clusters.map | $cluster_title, $cluster_param| {
            $cirrus_settings = {
                "$.search.remote.${cluster_param['short_cluster_name']}.seeds" => $cluster_param[
                    'unicast_hosts'].map |$unicast_host| {
                    "${unicast_host}:${cluster_param['transport_tcp_port']}"
                }
            }
        }
    }

    # This file is used to make sure puppet settings are aligned with API settings
    file { "/etc/elasticsearch/${title}/cirrus_check_settings.yaml":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => ordered_yaml($extracted_settings),
        mode    => '0444',
    }

    nrpe::monitor_service { "elasticsearch_setting_check_${port}":
        critical       => false,
        contact_group  => 'admins,team-discovery',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
        nrpe_command   => "/usr/lib/nagios/plugins/check_cirrus_settings.py --url http://localhost:${port}  --settings-file /etc/elasticsearch/${title}/cirrus_check_settings.yaml",
        description    => "ElasticSearch setting check - ${port}",
        check_interval => 720, # 12h
        retry_interval => 120, # 2h
        retries        => 1,
    }
}
