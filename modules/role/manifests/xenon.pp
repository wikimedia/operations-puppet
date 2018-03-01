# == Class: role::xenon
#
# Aggregates and graphs stack trace snapshots from MediaWiki
# application servers, showing where time is spent.
#
class role::xenon {
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
