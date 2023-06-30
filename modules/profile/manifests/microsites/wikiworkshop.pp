# SPDX-License-Identifier: Apache-2.0
# https://wikiworkshop.org (T242374)
class profile::microsites::wikiworkshop {

    httpd::site { 'wikiworkshop.org':
        content => template('profile/wikiworkshop/apache-wikiworkshop.org.erb'),
    }

    prometheus::blackbox::check::http { 'wikiworkshop.org':
        team               => 'serviceops-collab',
        severity           => 'task',
        path               => '/2023/',
        ip_families        => ['ip4'],
        force_tls          => true,
        status_matches     => [200],
        body_regex_matches => ['Wiki Workshop'],
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/wikiworkshop')

    git::clone { 'research/wikiworkshop':
        ensure    => latest,
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/wikiworkshop',
        branch    => 'master',
    }
}
