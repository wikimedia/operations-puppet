# mediawiki::web

class mediawiki::web ( $workers_limit = undef ) {
    include ::mediawiki
    include ::mediawiki::monitoring::webserver
    include ::mediawiki::web::config


    file { '/usr/local/apache':
        ensure => directory,
    }

    service { 'apache':
        ensure    => running,
        name      => 'apache2',
        enable    => false,
        subscribe => Exec['mw-sync'],
        require   => File['/etc/cluster'],
    }

    # Sync the server when we see apache is not running
    exec { 'apache-trigger-mw-sync':
        command => '/bin/true',
        unless  => '/bin/ps -C apache2',
        notify  => Exec['mw-sync'],
    }



    # Has to be less than apache, and apache has to be nice 0 or less to be
    # blue in ganglia.
    file { '/etc/init/ssh.override':
        content => "nice -10\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
