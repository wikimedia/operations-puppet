# SPDX-License-Identifier: Apache-2.0
#
define profile::pyrra::filesystem::slos::istio(
    String $team,
    String $slo_requests_target,
    String $slo_latency_target,
    Array[String] $datacenters = ['eqiad', 'codfw'],
    String $window = '12w',
    String $destination_canonical_service = "${title}-production",
    String $requests_errors_regex = '5..',
    String $latency_max_seconds_bucket = '5000',
    String $k8s_cluster_name = 'wikikube',
    Wmflib::Ensure $ensure = 'present'
) {
    $datacenters.each |$datacenter| {
        pyrra::filesystem::config { "${k8s_cluster_name}-${title}-requests-${datacenter}.yaml":
          ensure  => $ensure,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind'       => 'ServiceLevelObjective',
            'metadata'   => {
                'name'      => "${title}-requests",
                'namespace' => 'pyrra-o11y',
                'labels'    => {
                    'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                    'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
                    'pyrra.dev/site'    => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec'       => {
                'target'    => $slo_requests_target,
                'window'    => $window,
                'indicator' => {
                    'ratio' => {
                        'errors' => {
                            'metric' => "workload:istio_requests_total{source_workload_namespace=\"istio-system\", destination_canonical_service=\"${destination_canonical_service}\", response_code=~\"${requests_errors_regex}\", site=\"${datacenter}\" }",
                        },
                        'total'  => {
                            'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", destination_canonical_service=\"${destination_canonical_service}\", site=\"${datacenter}\" }",
                        },
                    },
                },
            },
          })
        }
        pyrra::filesystem::config { "${k8s_cluster_name}-${title}-latency-${datacenter}.yaml":
          ensure  => $ensure,
          content => to_yaml({
            'apiVersion' => 'pyrra.dev/v1alpha1',
            'kind'       => 'ServiceLevelObjective',
            'metadata'   => {
                'name'      => "${title}-latency",
                'namespace' => 'pyrra-o11y',
                'labels'    => {
                    'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                    'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
                    'pyrra.dev/site'    => "${datacenter}", #lint:ignore:only_variable_string
                },
            },
            'spec'       => {
                'target'    => $slo_latency_target,
                'window'    => $window,
                'indicator' => {
                    'latency'  => {
                        'success' => {
                            'metric' => "workload:istio_request_duration_milliseconds_bucket{source_workload_namespace=\"istio-system\", destination_canonical_service=\"${destination_canonical_service}\", le=\"${latency_max_seconds_bucket}\", site=\"${datacenter}\" }",
                        },
                        'total'   => {
                            'metric' => "workload:istio_request_duration_milliseconds_bucket{source_workload_namespace=\"istio-system\", destination_canonical_service=\"${destination_canonical_service}\", site=\"${datacenter}\" }",
                        },
                    },
                },
            },
          })
        }
    }
}
