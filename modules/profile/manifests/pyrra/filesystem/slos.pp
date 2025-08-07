# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos
# Filesystem defined SLOs in Pyrra.
#
class profile::pyrra::filesystem::slos (
    Array[String] $datacenters = lookup('datacenters'),
) {

    #lint:ignore:arrow_alignment

    include profile::pyrra::filesystem::slos::abstract_wikipedia
    include profile::pyrra::filesystem::slos::editing
    include profile::pyrra::filesystem::slos::ml
    include profile::pyrra::filesystem::slos::traffic
    include profile::pyrra::filesystem::slos::data_platform
    include profile::pyrra::filesystem::slos::observability

    # Etcd SLOs
    # etcd is limited to primary sites only
    ['eqiad', 'codfw'].each | $datacenter | {

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
                'alerting'  => {
                    'burnrates' => true
                },
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
                'alerting'  => {
                    'burnrates' => true
                },
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

    } # end of etcd's SLOs

    # Linkrecommendation internal service availability
    #
    # limited to primary sites only
    ['eqiad', 'codfw'].each | $datacenter | {
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
                'alerting'  => {
                    'burnrates' => true
                },
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
    } # end of Link Recommendation's SLOs

    #lint:endignore
}
