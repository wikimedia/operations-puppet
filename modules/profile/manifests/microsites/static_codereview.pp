# SPDX-License-Identifier: Apache-2.0
# static HTML archive of Extension:CodeReview
class profile::microsites::static_codereview {

    backup::set { 'static-codereview' : }

    prometheus::blackbox::check::http { 'static-codereview.wikimedia.org':
        team               => 'serviceops-collab',
        severity           => 'task',
        path               => '/MediaWiki/1.html',
        ip_families        => ['ip4'],
        force_tls          => true,
        status_matches     => [200],
        body_regex_matches => ['SVN CodeReview'],
    }

    wmflib::dir::mkdir_p('/srv/org/wikimedia/static-codereview')

    file { '/srv/org/wikimedia/static-codereview/index.html':
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => 'puppet:///modules/profile/microsites/static-codereview-index.html';
    }

    httpd::site { 'static-codereview.wikimedia.org':
        content  => template('profile/microsites/static-codereview.wikimedia.org.erb'),
        priority => 20,
    }
}
