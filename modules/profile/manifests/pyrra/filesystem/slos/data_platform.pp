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
    }

    #lint:endignore
}
