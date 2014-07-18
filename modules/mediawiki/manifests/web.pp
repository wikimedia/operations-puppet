# mediawiki::web

class mediawiki::web ( $workers_limit = undef) {
    tag 'mediawiki', 'mw-apache-config'

    include ::apache
    include ::mediawiki
    include ::mediawiki::monitoring::webserver

    $use_hhvm = ubuntu_version('>= trusty')
    $apache_server_limit = 256

    if is_integer($workers_limit) {
        $max_req_workers = min($workers_limit, $apache_server_limit)
    } else {
        $mem_available   = to_bytes($::memorytotal) * 0.7
        $mem_per_worker  = to_bytes('85M')
        $max_req_workers = min(floor($mem_available /$mem_per_worker), $apache_server_limit)
    }

    if $use_hhvm {
        class { 'mediawiki::hhvm':
            service => 'running',
            before  => Service['apache2']
        }
    }

    class { '::mediawiki::web::modules':
        use_hhvm        => $use_hhvm,
        max_req_workers => $max_req_workers
    }

    file { '/etc/apache2/apache2.conf':
        source  => 'puppet:///modules/mediawiki/apache/apache2.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    if ubuntu_version('>= trusty') {
        file { '/etc/apache2/envvars':
            ensure => present,
            source => 'puppet:///modules/mediawiki/apache/envvars.trusty'
        }
    } else {
        file { '/etc/apache2/envvars':
            ensure => present,
            source => 'puppet:///modules/mediawiki/apache/envvars.precise'
        }
    }

    # do not erase this for now, it may come handy soon...
    file { '/etc/apache2/wikimedia':
        ensure  => directory,
    }
}
