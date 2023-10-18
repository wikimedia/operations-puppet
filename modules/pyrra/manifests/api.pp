# SPDX-License-Identifier: Apache-2.0
# == Class: pyrra::api
#
# Pyrra frontend API/UI
#
# = Parameters
# [*prometheus_url*] The URL to the Prometheus to query
# [*api_url*] The URL to the API service like a Filesystem or Kubernetes Operator.

class pyrra::api(
    String $prometheus_url          = 'https://thanos-query.discovery.wmnet',
    String $prometheus_external_url = 'https://thanos.wikimedia.org',
    String $api_url                 = 'http://localhost:9444',
){

    ensure_packages(['pyrra'])

    systemd::service { 'pyrra-api':
        ensure         => present,
        restart        => true,
        override       => true,
        content        => systemd_template('pyrra-api'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }

}
