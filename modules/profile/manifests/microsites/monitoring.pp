# SPDX-License-Identifier: Apache-2.0
# Contains blackbox checks for miscweb services on Kubernetes (T300171)
class profile::microsites::monitoring {

    prometheus::blackbox::check::http { '15.wikipedia.org':
        team               => 'serviceops-collab',
        severity           => 'task',
        path               => '/',
        ip_families        => ['ip4'],
        force_tls          => true,
        status_matches     => [200],
        body_regex_matches => ['Wikipedia 15'],
        port               => 30443, # Kubernetes Ingress port
        ip4                => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
    }

    prometheus::blackbox::check::http { 'annual.wikimedia.org':
        team           => 'serviceops-collab',
        severity       => 'task',
        path           => '/2017/',
        ip_families    => ['ip4'],
        force_tls      => true,
        status_matches => [200],
        port           => 30443, # Kubernetes Ingress port
        ip4            => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
    }
}
