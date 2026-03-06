# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem::slos::ml

class profile::pyrra::filesystem::slos::ml {

    # Performance test for T387350
    profile::pyrra::filesystem::slos::istio { 'revertrisk-la':
        team                          => 'ml',
        slo_availability_target       => '95.0',
        slo_latency_target            => '95.0',
        destination_canonical_service => 'revertrisk-language-agnostic-predictor',
        enable_alerts                 => false,
        pyrra_namespace               => 'pyrra-o11y-pilot',
        prometheus_instance           => 'k8s-mlserve',
        k8s_cluster_name              => 'ml-serve',
    }

    profile::pyrra::filesystem::slos::istio { 'tonecheck':
        team                          => 'ml',
        slo_availability_target       => '95.0',
        slo_latency_target            => '90.0',
        destination_canonical_service => 'edit-check-predictor',
        latency_max_seconds_bucket    => '1000',
        enable_alerts                 => false,
        pyrra_namespace               => 'pyrra-o11y',
        latency_target_requests_regex => '2..',
        prometheus_instance           => 'k8s-mlserve',
        k8s_cluster_name              => 'ml-serve',
        revision                      => 1,
    }

}
