class mediawiki::monitoring::webserver ($ensure = 'present'){
    include ::stdlib
    include ::apache
    include ::network::constants

    if ubuntu_version('< trusty') {
        $endpoints = {
            'apc' => 'apc_stats.php'
        }
    }
    else {
        $endpoints = {}
        diamond::collector { 'hhvm_health':
            ensure   => $ensure,
            source   => 'puppet:///modules/mediawiki/monitoring/collectors/hhvm.py',
            settings => { url => '/check-health' },
            require  => Apache::Site['hhvm_admin'],
        }

        monitor_graphite_threshold { 'hhvm_queue_size':
            description     => 'HHVM queue size',
            metric          => "servers.${::hostname}.hhvm_healthCollector.queued.value",
            warning         => 10,
            critical        => 80,
            nagios_critical => false
        }

        $hhvm_max_threads = $::processorcount * 2

        monitor_graphite_threshold { 'hhvm_load':
            description     => 'HHVM busy threads',
            metric          => "servers.${::hostname}.hhvm_healthCollector.load.value",
            warning         => $hhvm_max_threads * 0.8,
            critical        => $hhvm_max_threads,
            nagios_critical => false
        }

    }

    # Basic vhost files
    file { '/var/www/monitoring':
        ensure  => ensure_directory($ensure),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Class['::mediawiki::packages']
    }


    apache::site {'monitoring':
        ensure   => present,
        priority => '99',
        content  => template('mediawiki/apache/monitoring.conf.erb'),
        require  => Package['apache2'],
    }

    # monitor definitions

    # This define is designed to be private to this class,
    # this is why it's defined within the class itself.
    # We are choosing convention over configuration here, which is usualy wise.
    define endpoint ($ensure = $::mediawiki::monitoring::webserver::ensure) {

        $endpoint = $::mediawiki::monitoring::webserver::endpoints[$title]

        file { "/var/www/monitoring/${endpoint}":
            ensure => $ensure,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => "puppet:///modules/mediawiki/monitoring/${endpoint}"
        }

        diamond::collector {"mw_${title}":
            ensure   => $ensure,
            source   => "puppet:///modules/mediawiki/monitoring/collectors/${title}.py",
            settings => { host => $::fqdn, url => "${title}" }
        }

    }

    $endpoint_list = keys($endpoints)
    mediawiki::monitoring::webserver::endpoint { $endpoint_list: }
}
