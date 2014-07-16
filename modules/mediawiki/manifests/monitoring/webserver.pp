class mediawiki::monitoring::webserver ($ensure = 'present'){
    include ::stdlib
    include ::apache

    $dir_ensure = $ensure ? {
        'present' => 'directory',
        default   => $ensure
    }

    $link_ensure = $ensure ? {
        'present' => 'link',
        default   => $ensure
    }

    $endpoints = {
        'apc' => 'apc_stats.php'
    }


    # Basic vhost files
    file { '/var/www/monitoring':
        ensure  => $dir_ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Class['::mediawiki::packages']
    }


    apache::site {'monitoring':
        ensure   => present,
        priority => '99',
        content  => template('mediawiki/apache/monitoring.conf.erb'),
        require  => Service['apache2'],
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
