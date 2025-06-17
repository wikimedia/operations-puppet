# SPDX-License-Identifier: Apache-2.0
#
define profile::pyrra::filesystem::slos::istio(
    String $team,
    String $slo_requests_target,
    Array[String] $datacenters = ['eqiad', 'codfw'],
    String $window = '4w',
    String $destination_canonical_service = "${title}-production",
    String $requests_errors_regex = '5..',
    String $latency_max_seconds_bucket = '5000',
    String $k8s_cluster_name = 'wikikube',
    Boolean $enable_alerts = false,
    String $pyrra_namespace = 'pyrra-o11y',
    Wmflib::Ensure $ensure = 'present',
    Optional[String] $slo_latency_target = undef,
    Optional[String] $latency_target_requests_regex = undef,
) {
    $datacenters.each |$datacenter| {
        pyrra::filesystem::config { "${k8s_cluster_name}-${title}-requests-${datacenter}.yaml":
          ensure  => $ensure,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind'       => 'ServiceLevelObjective',
            'metadata'   => {
                'name'      => "${title}-requests",
                'namespace' => "${pyrra_namespace}", #lint:ignore:only_variable_string
                'labels'    => {
                    'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                    'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
                    'pyrra.dev/site'    => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec'       => {
                'alerting'  => {
                    'burnrates' => $enable_alerts
                },
                'target'    => $slo_requests_target,
                'window'    => $window,
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\",  destination_canonical_service=\"${destination_canonical_service}\", response_code=~\"${requests_errors_regex}\", site=\"${datacenter}\" }",
                        },
                        'total'  => {
                            'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\",  destination_canonical_service=\"${destination_canonical_service}\", site=\"${datacenter}\" }",
                        },
                    },
                },
            },
          })
        }
        if $slo_latency_target {
            # We want to be able to trim the success part of the SLI based on the response code. For example, in some cases
            # it may makes sense to just pay attention to HTTP 20X responses, rather than a mixture of 20x/30x/40x all with
            # different latency performances.
            $base_latency_success_sli_labels = "source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", destination_canonical_service=\"${destination_canonical_service}\", le=\"${latency_max_seconds_bucket}\", site=\"${datacenter}\""
            $latency_success_sli = $latency_target_requests_regex ? {
                undef   => "istio_request_duration_milliseconds_bucket{${base_latency_success_sli_labels}}",
                default => "istio_request_duration_milliseconds_bucket{${base_latency_success_sli_labels}, response_code=~\"${latency_target_requests_regex}\"}"
            }
            pyrra::filesystem::config { "${k8s_cluster_name}-${title}-latency-${datacenter}.yaml":
              ensure  => $ensure,
              content => to_yaml({
                'apiVersion' => 'pyrra.dev/v1alpha1',
                'kind'       => 'ServiceLevelObjective',
                'metadata'   => {
                    'name'      => "${title}-latency",
                    'namespace' => "${pyrra_namespace}", #lint:ignore:only_variable_string
                    'labels'    => {
                        'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                        'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
                        'pyrra.dev/site'    => "${datacenter}", #lint:ignore:only_variable_string
                    },
                },
                'spec'       => {
                    'alerting'  => {
                        'burnrates' => $enable_alerts
                    },
                    'target'    => $slo_latency_target,
                    'window'    => $window,
                    'indicator' => {
                        'latency'  => {
                            'success' => {
                                'metric' => $latency_success_sli,
                            },
                            'total'   => {
                                'metric' => "istio_request_duration_milliseconds_count{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", destination_canonical_service=\"${destination_canonical_service}\", site=\"${datacenter}\" }",
                            },
                        },
                    },
                },
              })
            }
        }
    }
}
