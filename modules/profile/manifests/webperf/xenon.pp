# == Class: profile::webperf::xenon
#
# Aggregate stack traces from MediaWiki application servers,
# and help see where time is spent, with flame graphs.
#
# Stacks are received using a Redis instance, and periodically written to disk
# in text files and SVG files. These files are exposed over HTTP for use
# by profile::webperf::site at <https://performance.wikimedia.org/xenon/>.
#
class profile::webperf::xenon {
    include ::xenon

    class { '::httpd':
        modules => ['mime', 'proxy', 'proxy_http'],
    }

    redis::instance { '6379':
        settings => {
            maxmemory                   => '1Mb',
            stop_writes_on_bgsave_error => 'no',
            bind                        => '0.0.0.0',
        },
    }

    Service['redis-server'] ~> Service['xenon-log']

    httpd::site { 'xenon':
        content => template('role/apache/sites/xenon.erb'),
    }

    ferm::service { 'xenon_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::rule { 'xenon_redis':
        rule => 'saddr ($DOMAIN_NETWORKS) proto tcp dport 6379 ACCEPT;',
    }
}
