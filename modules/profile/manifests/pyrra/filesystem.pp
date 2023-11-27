# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem
#

class profile::pyrra::filesystem (
) {

    class { 'pyrra::filesystem': }

    # filesystem defined slos

    # Logstash Requests SLO - please see wikitech for details
    # https://wikitech.wikimedia.org/wiki/SLO/logstash

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


    $liftwing_revscoring_requests_slo = {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'liftwing-requests-revscoring',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'ml',
                'pyrra.dev/service' => 'liftwing-revscoring',
            },
        },
        'spec' => {
            'target' => '98.0',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => 'istio_requests_total{kubernetes_namespace="istio-system", destination_canonical_service="enwiki-articlequality-predictor-default", response_code=~"5.."}"}',
                    },
                    'total' => {
                        'metric' => 'istio_requests_total{kubernetes_namespace="istio-system", destination_canonical_service="enwiki-articlequality-predictor-default"}',
                    },
                    'grouping' => ['site', 'destination_service_namespace'],
                },
            },
        },
    }

    pyrra::filesystem::config { 'liftwing-requests.yaml':
      content => to_yaml($liftwing_revscoring_requests_slo),
    }

}
