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

    file_line { 'fix_apache_user':
        ensure => present,
        path   => '/etc/apache2/envvars',
        line   => 'export APACHE_RUN_USER=apache',
        match  => 'export APACHE_RUN_USER=www-data'
    }

    file_line { 'fix_apache_group':
        ensure => present,
        path   => '/etc/apache2/envvars',
        line   => 'export APACHE_RUN_GROUP=apache',
        match  => 'export APACHE_RUN_GROUP=www-data'
    }

    if ubuntu_version('>= trusty') {
        apache::def{ 'HHVM': }
    }

    # do not erase this for now, it may come handy soon...
    file { '/etc/apache2/wikimedia':
        ensure  => absent,
        recurse => true,
        force   => true,
    }
}
