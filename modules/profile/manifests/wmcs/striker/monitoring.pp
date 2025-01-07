# SPDX-License-Identifier: Apache-2.0
# Contains blackbox checks for toolsadmin (striker) (T373250)
class profile::wmcs::striker::monitoring {
    prometheus::blackbox::check::http { 'toolsadmin.wikimedia.org':
        team                    => 'wmcs',
        severity                => 'page',
        path                    => '/',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        body_regex_matches      => ['Toolforge admin console'],
        port                    => 443,
        ip4                     => ipresolve('toolsadmin.wikimedia.org', 4),
        certificate_expiry_days => 9,
    }
}
