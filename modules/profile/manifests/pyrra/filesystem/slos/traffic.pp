# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::traffic

class profile::pyrra::filesystem::slos::traffic (
    Array[String] $datacenters = lookup('datacenters'),
) {

    #lint:ignore:arrow_alignment
    $datacenters.each |$datacenter| {

        # Varnish uses one combined latency-availability SLI: A response is satisfactory
        # IF it spends less than 100 ms processing time in Varnish, AND it isn't a Varnish internal error.
        # SLO: In each DC, 99.9% of requests get satisfactory responses. (grouping by site)
        # Request Error Ratio SLI: The percentage of requests receiving unsatisfactory responses.
        #                          This is normally near zero; upward spikes represent incidents.
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
                    'alerting'  => {
                        'burnrates' => true
                    },
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
                    'alerting'  => {
                        'burnrates' => true
                    },
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
                    'alerting'  => {
                        'burnrates' => true
                    },
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

    }

    #lint:endignore
}
