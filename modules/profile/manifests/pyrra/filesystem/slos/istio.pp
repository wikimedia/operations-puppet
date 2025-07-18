# SPDX-License-Identifier: Apache-2.0
#
define profile::pyrra::filesystem::slos::istio (
    String $team,
    String $slo_availability_target,
    String $window = '4w',
    String $destination_canonical_service = $title,
    String $availability_errors_regex = '5..',
    String $latency_max_seconds_bucket = '5000',
    String $k8s_cluster_name = 'wikikube',
    Boolean $enable_alerts = false,
    String $pyrra_namespace = 'pyrra-o11y',
    Wmflib::Ensure $ensure = 'present',
    String $prometheus_instance = 'k8s',
    String $slo_success_ratio_requests_regex = '(2|3)..',
    Optional[String] $slo_latency_target = undef,
    Optional[String] $latency_target_requests_regex = undef,
    Optional[String] $slo_success_ratio_target = undef,
) {
    if $destination_canonical_service == $title {
        # Istio 1.15 uses the -production suffix in destination_canonical_service, 1.24 does not.
        # So if the destination_canonical_service is not overridden by the caller, produce a regex filter that matches both cases.
        $destination_canonical_service_filter = "destination_canonical_service=~\"${destination_canonical_service}(?:-production)?\""
    } else {
        # If the destination_canonical_service is overridden by the caller use a simple comparison instead of a regex.
        $destination_canonical_service_filter = "destination_canonical_service=\"${destination_canonical_service}\""
    }

    pyrra::filesystem::config { "${k8s_cluster_name}-${title}-availability.yaml":
      ensure  => $ensure,
      content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind'       => 'ServiceLevelObjective',
        'metadata'   => {
            'name'      => "${title}-availability",
            'namespace' => "${pyrra_namespace}", #lint:ignore:only_variable_string
            'labels'    => {
                'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
            },
        },
        'spec'       => {
            'alerting'  => {
                'burnrates' => $enable_alerts
            },
            'target'    => $slo_availability_target,
            'window'    => $window,
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", app=\"istio-ingressgateway\", ${destination_canonical_service_filter}, response_code=~\"${availability_errors_regex}\", prometheus=\"${prometheus_instance}\" }",
                    },
                    'total'  => {
                        'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", app=\"istio-ingressgateway\", ${destination_canonical_service_filter}, prometheus=\"${prometheus_instance}\" }",
                    },
                },
            },
        },
      })
    }
    # We want to be able to trim the success part of the SLI based on the response code. For example, in some cases
    # it may makes sense to just pay attention to HTTP 20X responses, rather than a mixture of 20x/30x/40x all with
    # different latency performances.
    $base_latency_success_sli_labels = "source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", app=\"istio-ingressgateway\", ${destination_canonical_service_filter}, le=\"${latency_max_seconds_bucket}\", prometheus=\"${prometheus_instance}\""
    $latency_success_sli = $latency_target_requests_regex ? {
        undef   => "istio_request_duration_milliseconds_bucket{${base_latency_success_sli_labels}}",
        default => "istio_request_duration_milliseconds_bucket{${base_latency_success_sli_labels}, response_code=~\"${latency_target_requests_regex}\"}"
    }
    pyrra::filesystem::config { "${k8s_cluster_name}-${title}-latency.yaml":
      ensure  => ($slo_latency_target != undef).bool2str('present', 'absent'),
      content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind'       => 'ServiceLevelObjective',
        'metadata'   => {
            'name'      => "${title}-latency",
            'namespace' => "${pyrra_namespace}", #lint:ignore:only_variable_string
            'labels'    => {
                'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
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
                        'metric' => "istio_request_duration_milliseconds_count{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", app=\"istio-ingressgateway\", ${destination_canonical_service_filter}, prometheus=\"${prometheus_instance}\" }",
                    },
                },
            },
        },
      })
    }

    # Experimental target to go alongside to the Service Availability one. In some cases, like Citoid's,
    # we may have multiple SLOs:
    # 1) Generic availability, for example in the Citoid's use case a 5xx is surely a backend issue.
    # 2) Success ratio, for example in the Citoid's use case whatever it is not a 2xx or a 3xx, since
    #    we also count 4xx in this case as a bad response (in particular, 404s are indicative of an issue
    #    with a third party service).
    # Two aspects of the same service, looked from different point of views.
    pyrra::filesystem::config { "${k8s_cluster_name}-${title}-success-ratio.yaml":
      ensure  => ($slo_success_ratio_target != undef).bool2str('present', 'absent'),
      content => to_yaml({
        'apiVersion' => 'pyrra.dev/v1alpha1',
        'kind'       => 'ServiceLevelObjective',
        'metadata'   => {
            'name'      => "${title}-success-ratio",
            'namespace' => "${pyrra_namespace}", #lint:ignore:only_variable_string
            'labels'    => {
                'pyrra.dev/team'    => "${team}", #lint:ignore:only_variable_string
                'pyrra.dev/service' => "${title}", #lint:ignore:only_variable_string
            },
        },
        'spec'       => {
            'alerting'  => {
                'burnrates' => $enable_alerts
            },
            'target'    => $slo_success_ratio_target,
            'window'    => $window,
            'indicator' => {
                'ratio' => {
                    'errors' => {
                        'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", app=\"istio-ingressgateway\", ${destination_canonical_service_filter}, response_code!~\"${slo_success_ratio_requests_regex}\", prometheus=\"${prometheus_instance}\" }",
                    },
                    'total'  => {
                        'metric' => "istio_requests_total{source_workload_namespace=\"istio-system\", source_workload=\"istio-ingressgateway\", app=\"istio-ingressgateway\", ${destination_canonical_service_filter}, prometheus=\"${prometheus_instance}\" }",
                    },
                },
            },
        },
      })
    }
}
