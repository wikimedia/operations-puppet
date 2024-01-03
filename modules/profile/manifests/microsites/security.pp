# SPDX-License-Identifier: Apache-2.0
# https://security.wikimedia.org (T257834)
class profile::microsites::security(
  $server_name = lookup('profile::microsites::security::server_name'),
  $server_admin = lookup('profile::microsites::security::server_admin'),
) {

    httpd::site { 'security.wikimedia.org':
        content => template('profile/security/security.wikimedia.org.erb'),
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/security')

    git::clone { 'wikimedia/security/landing-page':
        ensure    => latest,
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/security',
        branch    => 'master',
    }

    prometheus::blackbox::check::http { 'security.wikimedia.org':
        team               => 'collaboration-services',
        severity           => 'task',
        path               => '/',
        force_tls          => true,
        ip_families        => [ip4],
        body_regex_matches => ['Wikimedia Security'],
    }
}

