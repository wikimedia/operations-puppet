# == Class role::logging::mediawiki::errors
# udp2log on mwlog hosts forward MediaWiki exceptions and fatals
# to eventlog*, as configured in templates/udp2log/filters.mw.erb. This
# role provisions a metric module that reports error counts to StatsD.
#
class role::logging::mediawiki::errors {
    system::role { 'role::logging::mediawiki::errors':
        description => 'Report MediaWiki exceptions and fatals to StatsD',
    }

    class { 'mediawiki::monitoring::errors': }

    ferm::service { 'mediawiki-exceptions-logging':
        proto  => 'udp',
        port   => '8423',
        srange => '@resolve((mwlog1001.eqiad.wmnet mwlog2001.codfw.wmnet))',
    }
}
