# SPDX-License-Identifier: Apache-2.0
# Class ganeti::prometheus
#
# Install Prometheus exporter for Ganeti
#

class ganeti::prometheus(
    String $rapi_endpoint,
    String $rapi_ro_user,
    String $rapi_ro_password,
) {
    if debian::codename::ge('bullseye'){
        ensure_packages('prometheus-ganeti-exporter')

        ferm::service {'ganeti-prometheus-exporter':
            proto  => 'tcp',
            port   => '8080',
            srange => '$PRODUCTION_NETWORKS',
        }

        # Configuration files for Ganeti Prometheus exporter
        file { '/etc/prometheus/ganeti.ini':
            ensure  => present,
            owner   => 'prometheus',
            group   => 'prometheus',
            mode    => '0400',
            content => template('ganeti/prometheus-collector.erb')
        }

        service {'prometheus-ganeti-exporter':
            ensure => running,
        }

    }
}
