class mediawiki::monitoring::webserver( $ensure = present ) {
    include ::apache
    include ::network::constants

    if os_version('ubuntu < trusty') {
        $endpoints = {'apc' => 'apc_stats.php'}
    } else {
        $endpoints = {}

        require mediawiki::hhvm

        diamond::collector { 'hhvmHealth':
            ensure   => $ensure,
            source   => 'puppet:///modules/mediawiki/monitoring/collectors/hhvm.py',
            require  => Apache::Site['hhvm_admin'],
        }

        monitoring::graphite_threshold { 'hhvm_queue_size':
            description     => 'HHVM queue size',
            metric          => "servers.${::hostname}.hhvmHealthCollector.queued",
            warning         => 10,
            critical        => 80,
            percentage      => 30,
            nagios_critical => false
        }

        monitoring::graphite_threshold { 'hhvm_load':
            description     => 'HHVM busy threads',
            metric          => "servers.${::hostname}.hhvmHealthCollector.load",
            warning         => $::mediawiki::hhvm::max_threads*0.6,
            critical        => $::mediawiki::hhvm::max_threads * 0.9,
            percentage      => 30,
            nagios_critical => false
        }

    }

    file { '/var/www/monitoring':
        ensure  => ensure_directory($ensure),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Class['::mediawiki::packages'],
    }


    apache::site { 'monitoring':
        ensure   => $ensure,
        content  => template('mediawiki/apache/monitoring.conf.erb'),
        priority => 99,
        require  => Package['apache2'],
    }

    # monitor definitions

    # This define is designed to be private to this class,
    # this is why it's defined within the class itself.
    # We are choosing convention over configuration here, which is usualy wise.
    define endpoint( $ensure = $::mediawiki::monitoring::webserver::ensure ) {
        $endpoint = $::mediawiki::monitoring::webserver::endpoints[$title]

        file { "/var/www/monitoring/${endpoint}":
            ensure => $ensure,
            source => "puppet:///modules/mediawiki/monitoring/${endpoint}",
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
        }

        diamond::collector {"mw_${title}":
            ensure   => $ensure,
            source   => "puppet:///modules/mediawiki/monitoring/collectors/${title}.py",
            settings => { host => $::fqdn, url => $title }
        }

    }

    $endpoint_list = keys($endpoints)
    mediawiki::monitoring::webserver::endpoint { $endpoint_list: }


    # Provision `apachetop`, a top-like tool for observing Apache requests.

    require_package('apachetop')

    file { '/etc/profile.d/apachetop.sh':
        ensure  => $ensure,
        content => 'alias apachetop="sudo /usr/sbin/apachetop -f /var/log/apache2/other_vhosts_access.log"',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
