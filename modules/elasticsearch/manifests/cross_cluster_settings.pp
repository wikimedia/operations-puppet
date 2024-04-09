# SPDX-License-Identifier: Apache-2.0
# = Define: elasticsearch::cross_cluster_settings
define elasticsearch::cross_cluster_settings(
    Stdlib::Port $http_port,
    Hash[String, Elasticsearch::InstanceParams] $settings,
    Boolean $enable_remote_search,
) {

    $remote_clusters = $settings.filter |$instance| { $instance[1]['cluster_name'] != $title }
    $extracted_settings = $remote_clusters.map | $cluster_title, $cluster_param| {
        $cirrus_settings = {
            "cluster.remote.${cluster_param['short_cluster_name']}.seeds" => $cluster_param[
                'unicast_hosts'].map |$unicast_host| {
                "${unicast_host}:${cluster_param['transport_tcp_port']}"
            }
        }
    }

    # TODO: sanity check extracted_settings has what we expect
    $_extracted_settings = $extracted_settings[0].merge($extracted_settings[1])
    $cluster_settings_path = "/etc/elasticsearch/${title}/cirrus_check_settings.json"
    # This file is used to make sure puppet settings are aligned with API settings
    file { $cluster_settings_path:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => to_json_pretty({ 'persistent' => $_extracted_settings }),
        mode    => '0444',
    }
    file { "/usr/local/bin/set-cross-cluster-seeds_${http_port}.sh":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
        content => template('elasticsearch/set-cross-cluster-seeds.sh.erb'),
    }

    systemd::timer::job { 'push_cross_cluster_settings':
        command            => "/bin/bash /usr/local/bin/set-cross-cluster-seeds_${http_port}.sh",
        description        => "Auto set remote cluster seeds for ${title}",
        user               => 'root',
        monitoring_enabled => true,
        logging_enabled    => true,
        interval           => {
            'start'    => 'OnUnitActiveSec',
            'interval' => '15min', # every 5 min
        }
    }
}
