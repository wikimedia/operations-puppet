# SPDX-License-Identifier: Apache-2.0
# Installs helmfile and helmfile-diff, plus
# all the puppet-provided defaults and secrets for each service.
#
class profile::kubernetes::deployment_server::monitoring (){

    file { '/usr/local/bin/prometheus-check-k8s-opensearch-certificate-expiry':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/profile/kubernetes/deployment_server/check_k8s_opensearch_certificate_expiry.py'
    }

    prometheus::node_textfile { 'prometheus-check-k8s-opensearch-certificate-expiry':
        ensure         => 'present',
        interval       => '*:00:00',
        run_cmd        => '/usr/local/bin/prometheus-check-k8s-opensearch-certificate-expiry --outfile /var/lib/prometheus/node.d/opensearch-certificate-expiry.prom',
        extra_packages => ['python3-prometheus-client'],
    }
}
