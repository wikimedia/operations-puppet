define varnish::monitoring::instance($instance) {
    $port = $title
    monitoring::service { "varnish http ${instance} - port ${port}":
        description   => "Varnish HTTP ${instance} - port ${port}",
        check_command => "check_http_varnish!varnishcheck!${port}",
    }

    # We have found a correlation between the 503 errors described in T145661
    # and the expiry thread not being able to catch up with its mailbox
    file { '/usr/local/lib/nagios/plugins/check_varnish_expiry_mailbox_lag':
        ensure => present,
        source => 'puppet:///modules/role/varnish/check_varnish_expiry_mailbox_lag.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    nrpe::monitor_service { 'check_varnish_expiry_mailbox_lag':
        description    => "Check Varnish ${instance} expiry mailbox lag",
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_varnish_expiry_mailbox_lag',
        require        => File['/usr/local/lib/nagios/plugins/check_varnish_expiry_mailbox_lag'],
    }
}
