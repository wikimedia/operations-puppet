# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos

class profile::pyrra::filesystem::slos (
    Array[String] $datacenters = lookup('datacenters'),
) {

    # filesystem defined SLOs

    #lint:ignore:arrow_alignment

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
                        'metric' => 'istio_requests_total{kubernetes_namespace="istio-system", destination_canonical_service="enwiki-articlequality-predictor-default", response_code=~"5.."}',
                    },
                    'total' => {
                        'metric' => 'istio_requests_total{kubernetes_namespace="istio-system", destination_canonical_service="enwiki-articlequality-predictor-default"}',
                    },
                    'grouping' => ['site'],
                },
            },
        },
    }

    pyrra::filesystem::config { 'liftwing-requests.yaml':
      ensure  => absent,
      content => to_yaml($liftwing_revscoring_requests_slo),
    }

    $liftwing_revscoring_latency_slo = {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'liftwing-latency-revscoring',
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
                'latency' => {
                    'success' => {
                        'metric' => 'istio_request_duration_milliseconds_bucket{kubernetes_namespace="istio-system", destination_canonical_service="enwiki-articlequality-predictor-default", le="5000", response_code=~"2.."}'
                    },
                    'total' => {
                        'metric' => 'istio_request_duration_milliseconds_count{kubernetes_namespace="istio-system", destination_canonical_service="enwiki-articlequality-predictor-default", response_code=~"2.."}',
                    },
                    'grouping' => ['site'],
                },
            },
        },
    }

    pyrra::filesystem::config { 'liftwing-latency.yaml':
      ensure  => absent,
      content => to_yaml($liftwing_revscoring_latency_slo),
    }

    # Varnish uses one combined latency-availability SLI: A response is satisfactory IF it spends less than 100 ms processing time in Varnish, AND it isn't a Varnish internal error.
    # SLO: In each DC, 99.9% of requests get satisfactory responses. (grouping by site)
    # Request Error Ratio SLI: The percentage of requests receiving unsatisfactory responses. This is normally near zero; upward spikes represent incidents.
    # https://wikitech.wikimedia.org/wiki/SLO/Varnish


    # workaround grouping exported metrics limitation by setting datacenter
    $datacenters.each |$datacenter| {


    # Logstash Requests SLO - please see wikitech for details
    # https://wikitech.wikimedia.org/wiki/SLO/logstash

    # logstash is eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "logstash-requests-${datacenter}.yaml":
          content => to_yaml( {
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'logstash-requests-pilot',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'o11y',
                    'pyrra.dev/service' => 'logging',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '99.5',
                'window' => '12w',
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
    }


    # Varnish uses one combined latency-availability SLI: A response is satisfactory IF it spends less than 100 ms processing time in Varnish, AND it isn't a Varnish internal error.
    # SLO: In each DC, 99.9% of requests get satisfactory responses. (grouping by site)
    # Request Error Ratio SLI: The percentage of requests receiving unsatisfactory responses. This is normally near zero; upward spikes represent incidents.
    # https://wikitech.wikimedia.org/wiki/SLO/Varnish

    pyrra::filesystem::config { "varnish-requests-${datacenter}.yaml":
        content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'varnish-requests-pilot',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'traffic',
                'pyrra.dev/service' => 'varnish',
                'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
            },
        },
        'spec' => {
            'target' => '99.9',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => "varnish_sli_bad{site=\"${datacenter}\"}",
                    },
                    'total' => {
                        'metric' => "varnish_sli_all{site=\"${datacenter}\"}",
                    },
                },
            },
        }
        })
    }

    # Etcd SLOs
    #

    # etcd is limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {

    # Etcd requests/errors SLO

        pyrra::filesystem::config { "etcd-requests-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'etcd-requests',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'serviceops',
                    'pyrra.dev/service' => 'etcd',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '99.9',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "etcd_http_failed_total{code=~\"5..\",site=\"${datacenter}\"}",
                        },
                        'total' => {
                            'metric' => "etcd_http_received_total{site=\"${datacenter}\"}",
                        },
                    },
                },
            },
          })

        }

    # Etcd latency SLO

        pyrra::filesystem::config { "etcd-latency-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'etcd-latency',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'serviceops',
                    'pyrra.dev/service' => 'etcd',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '99.8',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "etcd_http_successful_duration_seconds_bucket{le=\"0.032\",site=\"${datacenter}\"}"
                        },
                        'total' => {
                            'metric' => "etcd_http_successful_duration_seconds_count{site=\"${datacenter}\"}",
                        },
                    },
                },
            },
          })
        }

    }

    }

    #lint:endignore

}
