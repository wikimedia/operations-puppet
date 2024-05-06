# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos

class profile::pyrra::filesystem::slos (
) {

    # filesystem defined SLOs

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

    $varnish_requests_slo = {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'varnish-requests-pilot',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'traffic',
                'pyrra.dev/service' => 'varnish',
            },
        },
        'spec' => {
            'target' => '99.9',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => 'varnish_sli_bad',
                    },
                    'total' => {
                        'metric' => 'varnish_sli_all',
                    },
                    'grouping' => ['site'],
                },
            },
        },
    }

    pyrra::filesystem::config { 'varnish-requests.yaml':
      content => to_yaml($varnish_requests_slo),
    }


    # Etcd SLOs
    #
    # Etcd requests/errors

    $etcd_requests_slo = {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'etcd-requests',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'serviceops',
                'pyrra.dev/service' => 'etcd',
            },
        },
        'spec' => {
            'target' => '99.9',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => 'etcd_http_failed_total{code=~"5.."}',
                    },
                    'total' => {
                        'metric' => 'etcd_http_received_total',
                    },
                    'grouping' => ['site'],
                },
            },
        },
    }

    pyrra::filesystem::config { 'etcd-requests.yaml':
      content => to_yaml($etcd_requests_slo),
    }

    # Etcd latency

    $etcd_latency_slo = {
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'etcd-latency',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'serviceops',
                'pyrra.dev/service' => 'etcd',
            },
        },
        'spec' => {
            'target' => '99.8',
            'window' => '12w',
            'indicator' => {
                'latency' => {
                    'success' => {
                        'metric' => 'etcd_http_successful_duration_seconds_bucket{le="0.032"}'
                    },
                    'total' => {
                        'metric' => 'etcd_http_successful_duration_seconds_count',
                    },
                    'grouping' => ['site'],
                },
            },
        },
    }

    pyrra::filesystem::config { 'etcd-latency.yaml':
      content => to_yaml($etcd_latency_slo),
    }

}
