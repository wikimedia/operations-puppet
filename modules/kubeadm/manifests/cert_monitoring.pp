# @summary monitor expiry of kubeadm issued certificates
# SPDX-License-Identifier: Apache-2.0
class kubeadm::cert_monitoring () {
    ensure_packages([
        'python3-dateutil',
        'python3-prometheus-client',
    ])

    file { '/usr/local/sbin/prometheus-kubeadm-cert-exporter':
        ensure => file,
        source => 'puppet:///modules/kubeadm/cert_monitoring/prometheus-kubeadm-cert-exporter.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    systemd::timer::job { 'prometheus-kubeadm-cert-exporter':
        ensure      => present,
        user        => 'root',
        description => 'exports Kubernetes/kubeadm certificate expiration timestamps as Prometheus metrics',
        command     => '/usr/local/sbin/prometheus-kubeadm-cert-exporter --outfile /var/lib/prometheus/node.d/kubeadm-cert.prom',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '20m'},
    }
}
