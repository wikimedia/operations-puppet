# SPDX-License-Identifier: Apache-2.0
# https://research.wikimedia.org (T183916)
class profile::microsites::research(
  Stdlib::Fqdn $server_name = lookup('profile::microsites::research::server_name'),
  String $server_admin = lookup('profile::microsites::research::server_admin'),
) {

    httpd::site { 'research.wikimedia.org':
        content => template('profile/research/apache-research.wikimedia.org.erb'),
    }

    prometheus::blackbox::check::http { 'research.wikimedia.org':
        team               => 'serviceops-collab',
        severity           => 'task',
        path               => '/',
        ip_families        => ['ip4'],
        force_tls          => true,
        status_matches     => [200],
        body_regex_matches => ['Wikimedia Research'],
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/research')

    git::clone { 'research/landing-page':
        ensure    => latest,
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/research',
        branch    => 'master',
    }

}

