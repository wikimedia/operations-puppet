# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::observability

class profile::pyrra::filesystem::slos::observability {

    #lint:ignore:arrow_alignment
    ['eqiad', 'codfw'].each | $datacenter | {
        # Logstash Requests SLO - please see wikitech for details
        # https://wikitech.wikimedia.org/wiki/SLO/logstash
        pyrra::filesystem::config { "logstash-requests-${datacenter}.yaml":
          content => to_yaml( {
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'logstash-requests-pilot-v2',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'o11y',
                    'pyrra.dev/service' => 'logging',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'alerting'  => {
                    'burnrates' => true
                },
                'target' => '99.5',
                'window' => '4w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "log_dead_letters_hits{site=\"${datacenter}\"}",
                        },
                        'total' => {
                            'metric' => "logstash_node_plugin_events_out_total{plugin_id=\"output/opensearch/logstash\",site=\"${datacenter}\"}",
                        },
                    },
                },
            },
          })
        }

        # Logstash Availability SLO - please see wikitech for details
        # https://wikitech.wikimedia.org/wiki/SLO/logstash

        pyrra::filesystem::config { "logstash-availability-${datacenter}.yaml":
          content => to_yaml( {
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'logstash-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'o11y',
                    'pyrra.dev/service' => 'logging',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'alerting'  => {
                    'burnrates' => true
                },
                'target' => '99.95',
                'window' => '4w',
                'indicator' => {
                    'bool_gauge' => {
                        'metric' => "logstash_sli_availability:bool{site=\"${datacenter}\"}",
                    },
                },
            },
          })
        }
    }

    #lint:endignore
}
