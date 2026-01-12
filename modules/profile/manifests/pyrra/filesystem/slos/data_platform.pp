# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::data_platform

class profile::pyrra::filesystem::slos::data_platform (
    Array[String] $datacenters = lookup('datacenters'),
) {

    #lint:ignore:arrow_alignment
    $datacenters.each |$datacenter| {

        # WDQS Availability (Main) SLO - WDQS uses one availability SLI: The percentage of all requests receiving a non-error response,
        #                                defined as one of: HTTP 200 (success), HTTP 403 (client banned), or HTTP 429 (client throttled).
        #                                Note that there is no latency guarantee in the SLO, so queries could take up to the timeout limit.
        #
        pyrra::filesystem::config { "wdqs-main-availability-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'wdqs-main-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'search',
                    'pyrra.dev/service' => 'wdqs',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'alerting'  => {
                    'burnrates' => false
                },
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "trafficserver_backend_requests_seconds_count{site=\"${datacenter}\",status!~\"200|403|429\",backend=\"wdqs-main.discovery.wmnet\"}",
                        },
                        'total' => {
                            'metric' => "trafficserver_backend_requests_seconds_count{site=\"${datacenter}\",backend=\"wdqs-main.discovery.wmnet\"}",
                        },
                    },
                },
            },
          })
        }
    } # End of WDQS' availability SLOs

    $datacenters.each | $datacenter | {
        # WDQS Availablity (Scholarly) SLO - WDQS uses one availability SLI: The percentage of all requests receiving a non-error response,
        #                                    defined as one of: HTTP 200 (success), HTTP 403 (client banned), or HTTP 429 (client throttled).
        #                                    Note that there is no latency guarantee in the SLO, so queries could take up to the timeout limit.
        #
        pyrra::filesystem::config { "wdqs-scholarly-availability-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'wdqs-scholarly-availability',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'search',
                    'pyrra.dev/service' => 'wdqs',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'alerting'  => {
                    'burnrates' => false
                },
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "trafficserver_backend_requests_seconds_count{site=\"${datacenter}\",status!~\"200|403|429\",backend=\"wdqs-scholarly.discovery.wmnet\"}",
                        },
                        'total' => {
                            'metric' => "trafficserver_backend_requests_seconds_count{site=\"${datacenter}\",backend=\"wdqs-scholarly.discovery.wmnet\"}",
                        },
                    },
                },
            },
          })
        }
    }

    ['eqiad', 'codfw'].each | $datacenter | {
        # WDQS main update lag - WDQS uses one SLI: The percentage of all active servers whose update lag is <10 minutes
        #
        # limited to primary sites only
        pyrra::filesystem::config { "wdqs-main-update-lag-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'wdqs-main-update-lag',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'search',
                    'pyrra.dev/service' => 'wdqs',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'alerting'  => {
                    'burnrates' => false
                },
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'bool_gauge' => {
                            'metric' => "wdqs_sli_main_update_lag:bool{site=\"${datacenter}\"}",
                    },
                },
            },
          })
        }

        # WDQS scholarly update lag - WDQS uses one SLI: The percentage of all active servers whose update lag is <10 minutes

        pyrra::filesystem::config { "wdqs-scholarly-update-lag-${datacenter}.yaml":
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind' => 'ServiceLevelObjective',
            'metadata' => {
                'name' => 'wdqs-scholarly-update-lag',
                'namespace' => 'pyrra-o11y',
                'labels' => {
                    'pyrra.dev/team' => 'search',
                    'pyrra.dev/service' => 'wdqs',
                    'pyrra.dev/site' => "${datacenter}",  #lint:ignore:only_variable_string
                },
            },
            'spec' => {
                'alerting'  => {
                    'burnrates' => false
                },
                'target' => '95',
                'window' => '12w',
                'indicator' => {
                    'bool_gauge' => {
                            'metric' => "wdqs_scholarly_sli_update_lag:bool{site=\"${datacenter}\"}",
                    },
                },
            },
          })
        }
    } # End of WDQS' SLOs

    # Search update lag - Search uses one availability SLI: The time after which page are edited enters the search cluster is <10 minutes
    #
    # limited to primary sites only
    ['eqiad', 'codfw'].each | $datacenter | {
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
                'alerting'  => {
                    'burnrates' => true
                },
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
    } # End of Search update lag

    # Experimentation Lab ("xLab") / MPIC SLOs
    #
    # These are versioned as we anticipate the need for future improvements
    # and don't necessarily want to simply overwrite the PromQL, as we want
    # to have consistency of the metrics, especially in downstream recorders.
    #
    # Refer to thanos_rules.yaml for the referenced metrics. Then take note:
    #
    # For EventGate events, system errors (for numerator before complement)
    # may be from arbitrary streams via schema fragments, but in general the
    # desired destination stream will be product_metrics.web_base (for
    # denominator). This means the error ratio may exaggerate SLO misses, which is
    # okay in the context of the event system success rate measurement.
    #
    # Validation errors include schema invalidation and system errors,
    # which themselves can be thought of as a special class of schema invalidation.
    # Event validation rate here is confined to product_metrics.web_base.
    #
    # For xLab server requests our original targets are 95% of requests being
    # both success & within 2 seconds, but our inbuilt bucketing has values at 1
    # and 2.5 seconds, so we opt for 1 second given the historical headroom.
    #
    # v1 Experimentation Lab ("xLab") / MPIC standalone event system success rate
    profile::pyrra::filesystem::slo { 'xlab-standalone-event-system-success-rate':
      sloname => 'xlab-standalone-event-system-success-rate',
      team    => 'experiment-platform',
      service => 'mpic',
      revision => 1,
      spec => {
          'alerting'  => {
              'burnrates' => true
          },
          'target' => '99.9',
          'window' => '4w',
          'indicator' => {
              'ratio' => {
                  'errors' => {
                      'metric' => 'xlab_sli_standalone_event_system_errors_total',
                  },
                  'total' => {
                      'metric' => 'xlab_sli_standalone_event_system_total',
                  },
              },
          },
      },
    } # end of v1 Experimentation Lab ("xLab") / MPIC standalone event system success rate
    # v1 Experimentation Lab ("xLab") / MPIC standalone event validation success rate
    profile::pyrra::filesystem::slo { 'xlab-standalone-event-validation-success-rate':
      sloname => 'xlab-standalone-event-validation-success-rate',
      team    => 'experiment-platform',
      service => 'mpic',
      revision => 1,
      spec => {
          'alerting'  => {
              'burnrates' => true
          },
          'target' => '95',
          'window' => '4w',
          'indicator' => {
              'ratio' => {
                  'errors' => {
                      'metric' => 'xlab_sli_standalone_event_validation_errors_total',
                  },
                  'total' => {
                      'metric' => 'xlab_sli_standalone_event_validation_total',
                  },
              },
          },
      },
    } # end of v1 Experimentation Lab ("xLab") / MPIC standalone event validation success rate

    # Experimentation Lab ("xLab") / MPIC combined latency and success
    profile::pyrra::filesystem::slo { 'xlab-combined-latency-success':
      sloname => 'xlab-combined-latency-success',
      team    => 'experiment-platform',
      service => 'mpic',
      revision => 1,
      spec => {
          'alerting'  => {
              'burnrates' => true
          },
          'target' => '95',
          'window' => '4w',
          'indicator' => {
              'latency' => {
                  'success' => {
                      'metric' => "http_request_duration_seconds_bucket{kubernetes_namespace=\"mpic\", method=~\"GET|POST\", path=~\"/api/v1/experiments|/api/v1/instruments|/contextual-attributes|/domains|/experiments|/instrument/.*|/instruments|/login|/login/callback|/logout|/okrs|/streams|/user|/wikis\", code!~\"5..\", le=\"1\", prometheus=\"k8s-dse\"}",
                  },
                  'total' => {
                      'metric' => "http_request_duration_seconds_count{kubernetes_namespace=\"mpic\", method=~\"GET|POST\", path=~\"/api/v1/experiments|/api/v1/instruments|/contextual-attributes|/domains|/experiments|/instrument/.*|/instruments|/login|/login/callback|/logout|/okrs|/streams|/user|/wikis\", prometheus=\"k8s-dse\"}",
                  },
              },
          },
      },
    } # end of v1 Experimentation Lab ("xLab") / MPIC combined latency and success

    # MediaWiki Content History completeness SLO
    # Please note: this SLO is very different from the rest, since the SLI
    # metrics create daily datapoints (generated from batch jobs) indicating
    # 1) total: the total number of days that has passed (+1 daily basically)
    # 2) error: +1 if the completeness maximum error threshold is breached
    #    (different from the SLO one and internal to DPE).
    # So the error budget measures the amount of days that can cross the max
    # completeness error threshold.
    profile::pyrra::filesystem::slo { 'mediawiki-content-history-completeness':
      sloname => 'mediawiki-content-history-completeness',
      team    => 'data-platform',
      service => 'mediawiki-content-history',
      revision => 2,
      spec => {
          'alerting'  => {
              'burnrates' => false
          },
          'target' => '85.0',
          'window' => '4w',
          'indicator' => {
              'ratio' => {
                  'errors' => {
                      'metric' => 'wmf_content_mediawiki_content_history_v1_completeness_sli_alarms',
                  },
                  'total' => {
                      'metric' => 'wmf_content_mediawiki_content_history_v1_completeness_sli_days',
                  },
              },
          },
      },
    } # end of MediaWiki Content History completeness SLO

    #lint:endignore
}
