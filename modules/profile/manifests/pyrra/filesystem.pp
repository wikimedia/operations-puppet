# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem
#

class profile::pyrra::filesystem (
) {

    class { 'pyrra::filesystem': }

    # filesystem defined slos

    $logstash_requests_slo = {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'logstash-requests-pilot',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'o11y',
                'pyrra.dev/service' => 'logging',
            },
        },
        'spec' => {
            'target' => '99.5',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => 'log_dead_letters_hits',
                    },
                    'total' => {
                        'metric' => 'logstash_node_plugin_events_out_total{plugin_id="output/opensearch/logstash"}',
                    },
                    'grouping' => ['site'],
                },
            },
        },
    }


    pyrra::filesystem::config { 'logstash-requests.yaml':
      content => to_yaml($logstash_requests_slo),
    }


}
