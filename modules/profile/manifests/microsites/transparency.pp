# SPDX-License-Identifier: Apache-2.0
# Provisions the Wikimedia Transparency Report static site
# hosted at <http://transparency.wikimedia.org>.
#
class profile::microsites::transparency {

    $repo_dir = '/srv/org/wikimedia/TransparencyReport'
    $docroot  = "${repo_dir}/build"

    git::clone { 'wikimedia/TransparencyReport':
        ensure    => present,
        directory => $repo_dir,
    }

    httpd::site { 'transparency.wikimedia.org':
        content => template('profile/microsites/transparency.wikimedia.org.erb'),
    }

    prometheus::blackbox::check::http { 'transparency.wikimedia.org':
        team             => 'serviceops-collab',
        severity         => 'task',
        path             => '/',
        force_tls        => true,
        ip_families      => [ip4],
        status_matches   => [301],
        follow_redirects => false,
    }

    httpd::site { 'transparency-archive.wikimedia.org':
        content => template('profile//microsites/transparency-archive.wikimedia.org.erb'),
    }

    prometheus::blackbox::check::http { 'transparency-archive.wikimedia.org':
        team               => 'serviceops-collab',
        severity           => 'task',
        path               => '/',
        force_tls          => true,
        ip_families        => [ip4],
        body_regex_matches => ['Transparency'],
    }
}
