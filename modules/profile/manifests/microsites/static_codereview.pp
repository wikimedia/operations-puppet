# SPDX-License-Identifier: Apache-2.0
# static HTML archive of Extension:CodeReview
class profile::microsites::static_codereview {

    backup::set { 'static-codereview' : }

    monitoring::service { 'static-codereview-http':
        description   => 'Static CodeReview archive HTTP',
        check_command => 'check_http_url!static-codereview.wikimedia.org!/MediaWiki/1.html',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Static-codereview.wikimedia.org',
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
