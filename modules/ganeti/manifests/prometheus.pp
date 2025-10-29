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
    ensure_packages([
        'prometheus-ganeti-exporter',
        'python3-cryptography',
        'python3-prometheus-client',
    ])

    firewall::service {'ganeti-prometheus-exporter':
        proto    => 'tcp',
        port     => 8080,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    # Configuration files for Ganeti Prometheus exporter
    file { '/etc/ganeti/prometheus.ini':
        ensure  => present,
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0400',
        content => template('ganeti/prometheus-collector.erb')
    }

    file { '/usr/local/sbin/prometheus-ganeti-ca-exporter' :
        ensure => present,
        mode   => '0544',
        source => 'puppet:///modules/ganeti/prometheus-ganeti-ca-exporter.py',
    }

    service {'prometheus-ganeti-exporter':
        ensure => running,
    }

    profile::auto_restarts::service { 'prometheus-ganeti-exporter': }

    systemd::timer::job { 'prometheus-ganeti-ca-exporter':
        ensure      => stdlib::ensure($facts['ganeti_master'] == $facts['fqdn']),
        user        => 'root',
        description => 'Exports Prometheus metrics about the internal Ganeti CA',
        command     => '/usr/local/sbin/prometheus-ganeti-ca-exporter --outfile /var/lib/prometheus/node.d/ganeti-ca.prom --cert-path /var/lib/ganeti/server.pem',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'daily',
        },
    }
}
