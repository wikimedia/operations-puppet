# SPDX-License-Identifier: Apache-2.0
# Contains blackbox checks for miscweb services on Kubernetes (T300171)
class profile::microsites::monitoring {

    prometheus::blackbox::check::http { '15.wikipedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        body_regex_matches      => ['Wikipedia 15'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'annual.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/2017/',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'bienvenida.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => [ip4],
        body_regex_matches      => ['enciclopedia'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

        prometheus::blackbox::check::http { 'transparency.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => [ip4],
        status_matches          => [302],
        follow_redirects        => false,
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'transparency-archive.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => [ip4],
        body_regex_matches      => ['Transparency'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'tendril.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => [ip4],
        body_regex_matches      => ['retired'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'dbtree.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => [ip4],
        body_regex_matches      => ['retired'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'wikiworkshop.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/2023/',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        body_regex_matches      => ['Wiki Workshop'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'research.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        body_regex_matches      => ['Wikimedia Research'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'static-codereview.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/MediaWiki/1.html',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        body_regex_matches      => ['Code Review'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'design.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => ['ip4'],
        body_regex_matches      => ['Foundation Design'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { 'security.wikimedia.org':
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        force_tls               => true,
        ip_families             => ['ip4'],
        body_regex_matches      => ['Wikimedia Security'],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }
}
