# mediawiki::web

class mediawiki::web ( $workers_limit = undef ) {
    include ::mediawiki
    include ::mediawiki::monitoring::webserver
    include ::mediawiki::web::config

    if is_integer($workers_limit) {
        $max_req_workers = $workers_limit
    } else {
        $mem_available   = to_bytes($::memorytotal) * 0.7
        $mem_per_worker  = to_bytes('85M')
        $max_req_workers = inline_template('<%= ( @mem_available / @mem_per_worker ).to_i %>')
    }

    if ! defined($mw_use_local_resources) {
        # This is used in the apache2.conf template to switch from
        # rsync-based resources to puppet-managed ones
        $mw_use_local_resources = false
    }

    file { '/etc/apache2/apache2.conf':
        content => template('mediawiki/apache/apache2.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache'],
    }

    file { '/etc/apache2/envvars':
        source => 'puppet:///modules/mediawiki/apache/envvars.appserver',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Service['apache'],
    }

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
