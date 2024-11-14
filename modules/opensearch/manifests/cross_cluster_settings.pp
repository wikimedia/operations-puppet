# SPDX-License-Identifier: Apache-2.0
# = Define: opensearch::cross_cluster_settings
#
# When provided the set of configured clusters this will auto-update
# the cluster settings with cross-cluster configuration.
#
# Generally shouldn't be applied to all nodes in a cluster, they would
# all be attempting to update the same cluster settings. Suggest only
# applying to master-capable nodes or an equivilant shortlist.
#
# == Parameters:
#
# - $settings: The cluster settings, as provided to the `opensearch`
#   module.
define opensearch::cross_cluster_settings(
    Hash[String, Opensearch::InstanceParams] $settings,
    Boolean $enable_remote_search,
    String $instance_name = $title,
) {
    $cluster_name = $settings[$instance_name]['cluster_name']
    $config_dir = "/etc/opensearch/${cluster_name}"
    $http_port = $settings[$instance_name]['http_port']

    $remote_clusters = $settings.filter |$instance| { $instance[0] != $instance_name }
    $extracted_settings = $remote_clusters.reduce({}) | $agg, $kv_pair| {
        $cluster_title = $kv_pair[0]
        $cluster_param = $kv_pair[1]
        $key = "cluster.remote.${cluster_param['short_cluster_name']}.seeds"
        $seeds = $cluster_param['unicast_hosts'].map |$unicast_host| {
            "${unicast_host}:${cluster_param['transport_tcp_port']}"
        }
        $agg + [$key, $seeds]
    }

    # This file is used to make sure puppet settings are aligned with API settings
    $cluster_settings_path = "${config_dir}/cirrus_check_settings.json"
    file { $cluster_settings_path:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => to_json_pretty({ 'persistent' => $extracted_settings }),
        mode    => '0444',
    }

    $script = "/usr/local/bin/set-cross-cluster-seeds_${http_port}.sh"
    file { $script:
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
        content => template('opensearch/set-cross-cluster-seeds.sh.erb'),
    }

    systemd::timer::job { "push_cross_cluster_settings_${http_port}":
        command            => "/bin/bash ${script}",
        description        => "Auto set remote cluster seeds for ${instance_name}",
        user               => 'root',
        monitoring_enabled => true,
        logging_enabled    => true,
        interval           => {
            'start'    => 'OnUnitActiveSec',
            'interval' => '15min', # every 5 min
        }
    }
}
