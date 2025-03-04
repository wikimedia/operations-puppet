# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos

class profile::pyrra::filesystem::slos (
    Array[String] $datacenters = lookup('datacenters'),
) {

    # filesystem defined SLOs

    #lint:ignore:arrow_alignment

    # workaround grouping exported metrics limitation by setting site/datacenter via puppet
    $datacenters.each |$datacenter| {


    # liftwing SLOs are temporarily disabled due to resource consumption please see T368953 & T302995
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-articlequality-requests-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-articlequality-requests',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '98.0',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{kubernetes_namespace=\"istio-system\", destination_canonical_service=\"enwiki-articlequality-predictor-default\", response_code=~\"5..\", site=\"${datacenter}\" }",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{kubernetes_namespace=\"istio-system\", destination_canonical_service=\"enwiki-articlequality-predictor-default\", site=\"${datacenter}\" }",
                        },
                    },
                },
            },
          })
        }
    }

    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-articlequality-latency-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-articlequality-latency',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '98.0',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "istio_request_duration_milliseconds_bucket{kubernetes_namespace=\"istio-system\", destination_canonical_service=\"enwiki-articlequality-predictor-default\", le=\"5000\", response_code!~\"[345]..\", site=\"${datacenter}\" }",
                        },
                        'total' => {
                            'metric' => "istio_request_duration_milliseconds_count{kubernetes_namespace=\"istio-system\", destination_canonical_service=\"enwiki-articlequality-predictor-default\", response_code!~\"[345]..\", site=\"${datacenter}\" }",
                        },
                    },
                },
            },
          })
        }
    }

    # Lift Wing Recommendation API NG service latency - 95% of successful requests (2xx status code) are answered within 10s.
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "liftwing-api-ng-latency-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-api-ng-latency',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "istio_request_duration_milliseconds_bucket{site=~\"${datacenter}\",  le=\"10000\", response_code=~\"2..\", destination_service_namespace=\"recommendation-api-ng\", destination_canonical_service=\"recommendation-api-ng-main\"}",
                        },
                        'total' => {
                            'metric' => "istio_request_duration_milliseconds_count{site=~\"${datacenter}\",  response_code=~\"2..\", destination_service_namespace=\"recommendation-api-ng\", destination_canonical_service=\"recommendation-api-ng-main\"}",
                        },
                    },
                },
            },
          })
        }
    }

    # Lift Wing Recommendation API NG service availability - 95% of requests are successful (2|3|4xx status code)
    #
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-api-ng-availability-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-api-ng-availability',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{response_code!~\"(2|3|4)..\", site=~\"${datacenter}\",  destination_service_namespace=\"recommendation-api-ng\", destination_canonical_service=\"recommendation-api-ng-main\"}",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{response_code=~\"...\", site=~\"${datacenter}\",  destination_service_namespace=\"recommendation-api-ng\", destination_canonical_service=\"recommendation-api-ng-main\"}",
                        },
                    },
                },
            },
          })
        }
    }


    # Lift Wing Revscoring services latency - 98% of successful requests (2xx status code) are answered within 5s.
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "liftwing-revscoring-latency-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-revscoring-latency',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '98',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "istio_request_duration_milliseconds_bucket{site=~\"${datacenter}\",  le=\"5000\", response_code=~\"2..\", destination_service_namespace=~\"revscoring.*\"}",
                        },
                        'total' => {
                            'metric' => "istio_request_duration_milliseconds_count{site=~\"${datacenter}\",  response_code=~\"2..\", destination_service_namespace=~\"revscoring.*\"}",
                        },
                    },
                },
            },
          })
        }
    }

    # Lift Wing Revscoring services availability - 98% of requests are successful (2xx status code).
    #
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-revscoring-availability-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-revscoring-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '98',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{response_code!~\"(2|3|4)..\", site=~\"${datacenter}\",  destination_service_namespace=~\"revscoring.*\"}",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{response_code=~\"...\", site=~\"${datacenter}\",  destination_service_namespace=~\"revscoring.*\"}",
                        },
                    },
                },
            },
          })
        }
    }


    # Lift Wing Revert Risk Language Agnostic service latency - 98% of successful requests (2xx status code) are answered within 500ms.
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "liftwing-revert-risk-lang-agnostic-latency-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-revert-risk-lang-agnostic-latency',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '98',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "istio_request_duration_milliseconds_bucket{site=~\"${datacenter}\",  le=\"500\", response_code=~\"2..\", destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-language-agnostic-predictor-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_request_duration_milliseconds_count{site=~\"${datacenter}\",  response_code=~\"2..\", destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-language-agnostic-predictor-default\"}",
                        },
                    },
                },
            },
          })
        }
    }

    # Lift Wing Revert Risk Language Agnostic service availability - 98% of requests are successful (2xx status code)
    #
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-revert-risk-lang-agnostic-availability-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-revert-risk-lang-agnostic-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '98',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{response_code!~\"(2|3|4)..\", site=~\"${datacenter}\",  destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-language-agnostic-predictor-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{response_code=~\"...\", site=~\"${datacenter}\",  destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-language-agnostic-predictor-default\"}",
                        },
                    },
                },
            },
          })
        }
    }


    # Lift Wing Revert Risk MultiLingual service latency - 95% of successful requests (2xx status code) are answered within 5000ms.
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "liftwing-revert-risk-multilingual-latency-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-revert-risk-multilingual-latency',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "istio_request_duration_milliseconds_bucket{site=~\"${datacenter}\",  le=\"5000\", response_code=~\"2..\", destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-multilingual-predictor-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_request_duration_milliseconds_count{site=~\"{datacenter}\",  response_code=~\"2..\", destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-multilingual-predictor-default\"}",
                        },
                    },
                },
            },
          })
        }
    }

    # Lift Wing Revert Risk MultiLingual service availability - 95% of requests are successful (2xx status code).
    #
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-revert-risk-multilingual-availability-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-revert-risk-multilingual-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{response_code!~\"(2|3|4)..\", site=~\"${datacenter}\",  destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-multilingual-predictor-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{response_code=~\"...\", site=~\"${datacenter}\",  destination_service_namespace=\"revertrisk\", destination_canonical_service=\"revertrisk-multilingual-predictor-default\"}",
                        },
                    },
                },
            },
          })
        }
    }


    # Lift Wing Article Topic Outlink service latency - 95% of successful requests (2xx status code) are answered within 5000ms.
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "liftwing-articletopic-outlink-latency-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-articletopic-outlink-latency',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'latency' => {
                        'success' => {
                            'metric' => "istio_request_duration_milliseconds_bucket{site=~\"${datacenter}\",  le=\"5000\", response_code=~\"2..\", destination_service_namespace=\"articletopic-outlink\", destination_canonical_service=\"outlink-topic-model-transformer-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_request_duration_milliseconds_count{site=~\"${datacenter}\",  response_code=~\"2..\", destination_service_namespace=\"articletopic-outlink\", destination_canonical_service=\"outlink-topic-model-transformer-default\"}",
                        },
                    },
                },
            },
          })
        }
    }

    # Lift Wing Article Topic Outlink service availability - 95% of requests are successful (2xx status code).
    #
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-articletopic-outlink-availability-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-articletopic-outlink-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{response_code!~\"(2|3|4)..\", site=~\"${datacenter}\",  destination_service_namespace=\"articletopic-outlink\", destination_canonical_service=\"outlink-topic-model-transformer-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{response_code=~\"...\", site=~\"${datacenter}\",  destination_service_namespace=\"articletopic-outlink\", destination_canonical_service=\"outlink-topic-model-transformer-default\"}",
                        },
                    },
                },
            },
          })
        }
    }


    # "Lift Wing Readability service latency - 95% of successful requests (2xx status code) are answered within 5000ms.
    #
    # limited to primary sites only
        if $datacenter in ['eqiad', 'codfw'] {
            pyrra::filesystem::config { "liftwing-readability-latency-${datacenter}.yaml":
              ensure => absent,
              content => to_yaml({
                'apiVersion' => 'pyrra.dev/v1alpha1',
                'kind' => 'ServiceLevelObjective',
                'metadata' => {
                    'name' => 'liftwing-readability-latency',
                    'namespace' => 'pyrra-o11y',
                    'labels' => {
                        'pyrra.dev/team' => 'ml',
                        'pyrra.dev/service' => 'liftwing',
                        'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                    },
                },
                'spec' => {
                    'target' => '95',
                    'window' => '12w',
                    'indicator' => {
                        'latency' => {
                            'success' => {
                                'metric' => "istio_request_duration_milliseconds_bucket{site=~\"${datacenter}\",  le=\"5000\", response_code=~\"2..\", destination_service_namespace=\"readability\", destination_canonical_service=\"readability-predictor-default\"}",
                            },
                            'total' => {
                                'metric' => "istio_request_duration_milliseconds_count{site=~\"${datacenter}\",  response_code=~\"2..\", destination_service_namespace=\"readability\", destination_canonical_service=\"readability-predictor-default\"}",
                            },
                        },
                    },
                },
              })
            }
        }

    # Lift Wing Readability service availability - 95% of requests are successful (2xx status code).
    #
    # liftwing is in eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
        pyrra::filesystem::config { "liftwing-readability-availability-${datacenter}.yaml":
          ensure => absent,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'liftwing-readability-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'liftwing',
                    'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{response_code!~\"(2|3|4)..\", site=~\"${datacenter}\",  destination_service_namespace=\"readability\", destination_canonical_service=\"readability-predictor-default\"}",
                        },
                        'total' => {
                            'metric' => "istio_requests_total{response_code=~\"...\", site=~\"${datacenter}\",  destination_service_namespace=\"readability\", destination_canonical_service=\"readability-predictor-default\"}",
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

    # Logstash Availability SLO - please see wikitech for details
    # https://wikitech.wikimedia.org/wiki/SLO/logstash

    # logstash is eqiad/codfw only
    if $datacenter in [ 'eqiad', 'codfw' ] {
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
                'target' => '99.95',
                'window' => '12w',
                'indicator' => {
                    'bool_gauge' => {
                        'metric' => "logstash_sli_availability:bool{site=\"${datacenter}\"}",
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

    ['cache_text', 'cache_upload'].each |$varnish_cluster| {
    pyrra::filesystem::config { "varnish-combined-${datacenter}-${varnish_cluster}.yaml":
        content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'varnish-combined',
            'namespace' => 'pyrra-o11y-pilot',
            'labels' => {
                'pyrra.dev/team' => 'traffic',
                'pyrra.dev/service' => 'varnish',
                'pyrra.dev/site' => "${datacenter}", #lint:ignore:only_variable_string
                'pyrra.dev/cluster' => "${varnish_cluster}", #lint:ignore:only_variable_string
            },
        },
        'spec' => {
            'target' => '99.9',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => "varnish_sli_bad{site=\"${datacenter}\",cluster=\"${varnish_cluster}\"}",
                    },
                    'total' => {
                        'metric' => "varnish_sli_all{site=\"${datacenter}\",cluster=\"${varnish_cluster}\"}",
                    },
                },
            },
        }
        })
    }
    }

    # HAProxy SLO
    #
    # HAProxy uses one combined latency-availability SLI: A response is satisfactory if it spends less than 50 ms processing time in HAProxy, and it isn't an HAProxy internal error.
    #

    ['cache_text', 'cache_upload'].each |$haproxy_cluster| {
        pyrra::filesystem::config { "haproxy-combined-${datacenter}-${haproxy_cluster}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'haproxy-combined',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'traffic',
                    'pyrra.dev/service' => 'haproxy',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                    'pyrra.dev/cluster' => "${haproxy_cluster}",   #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '99.9',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "haproxy_sli_bad{cluster=~\"${haproxy_cluster}\",site=~\"${datacenter}\"}",
                        },
                        'total' => {
                            'metric' => "haproxy_sli_total{ cluster=~\"${haproxy_cluster}\",site=~\"${datacenter}\"}",
                        },
                    },
                },
            },
          })
        }

    }

    # Trafficserver SLO
    #
    # Trafficserver uses one combined latency-availability SLI: A response is satisfactory if it spends less than 150 ms processing time in Trafficserver,
    # and it isn't a Trafficserver internal error.
    #

    ['cache_text', 'cache_upload'].each |$trafficserver_cluster| {
        pyrra::filesystem::config { "trafficserver-combined-${datacenter}-${trafficserver_cluster}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'trafficserver-combined',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'traffic',
                    'pyrra.dev/service' => 'haproxy',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                    'pyrra.dev/cluster' => "${trafficserver_cluster}",   #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '99.7',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "trafficserver_backend_sli_bad{cluster=~\"${trafficserver_cluster}\",site=~\"${datacenter}\"}",
                        },
                        'total' => {
                            'metric' => "trafficserver_backend_sli_total{cluster=~\"${trafficserver_cluster}\",site=~\"${datacenter}\"}",
                        },
                    },
                },
            },
          })
        }

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

    # Linkrecommendation internal service availability
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "linkrecommendation-requests-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'linkrecommendation-requests',
                'namespace' => 'pyrra-o11y-pilot',
                'labels' => {
                    'pyrra.dev/team' => 'ml',
                    'pyrra.dev/service' => 'linkrecommendation',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "linkrecommendation_gunicorn_requests_total{app=\"linkrecommendation\", site=~\"${datacenter}\", prometheus=\"k8s\", status!~\"2..\"}",
                        },
                        'total' => {
                            'metric' => "linkrecommendation_gunicorn_requests_total{app=\"linkrecommendation\", site=~\"${datacenter}\", prometheus=\"k8s\"}",
                        },
                    },
                },
            },
          })
        }

    }

    # WDQS Availability SLO - WDQS uses one availability SLI: The percentage of all requests receiving a non-error response,
    #                         defined as one of: HTTP 200 (success), HTTP 403 (client banned), or HTTP 429 (client throttled).
    #                         Note that there is no latency guarantee in the SLO, so queries could take up to the timeout limit.
    #
    pyrra::filesystem::config { "wdqs-availability-${datacenter}.yaml":
      content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind' => 'ServiceLevelObjective',
        'metadata' => {
            'name' => 'wdqs-availability',
            'namespace' => 'pyrra-o11y',
            'labels' => {
                'pyrra.dev/team' => 'search',
                'pyrra.dev/service' => 'wdqs',
                'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
            },
        },
        'spec' => {
            'target' => '95',
            'window' => '12w',
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => "trafficserver_backend_requests_seconds_count{site=\"${datacenter}\",status!~\"200|403|429\",backend=\"wdqs.discovery.wmnet\"}",
                    },
                    'total' => {
                        'metric' => "trafficserver_backend_requests_seconds_count{site=\"${datacenter}\",backend=\"wdqs.discovery.wmnet\"}",
                    },
                },
            },
        },
      })
    }

    # WDQS update lag - WDQS uses one SLI: The percentage of all active servers whose update lag is <10 minutes
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "wdqs-update-lag-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'wdqs-update-lag',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'search',
                    'pyrra.dev/service' => 'wdqs',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'bool_gauge' => {
                            'metric' => "wdqs_sli_update_lag:bool{site=\"${datacenter}\"}",
                    },
                },
            },
          })
        }
    }

    # Search update lag - Search uses one availability SLI: The time after which page are edited enters the search cluster is <10 minutes
    #
    # limited to primary sites only
    if $datacenter in ['eqiad', 'codfw'] {
        pyrra::filesystem::config { "search-update-lag-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'search-update-lag',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'search',
                    'pyrra.dev/service' => 'search',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'bool_gauge' => {
                            'metric' => "search_sli_update_lag:bool{site=\"${datacenter}\",job_name=~\"cirrus_streaming_updater_consumer_search_${datacenter}\", prometheus=\"k8s\"}",
                    },
                },
            },
          })
        }
    }

    }

    #lint:endignore

}
