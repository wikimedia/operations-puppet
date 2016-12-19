class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    include ::role::mediawiki::scaler
    include ::mediawiki::jobrunner
    include ::base::firewall

    ferm::service { 'mediawiki-jobrunner-videoscalers':
        proto   => 'tcp',
        port    => $::mediawiki::jobrunner::port,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    # Change the apache2.conf Timeout setting
    augeas { 'apache timeout':
        incl    => '/etc/apache2/apache2.conf',
        lens    => 'Httpd.lns',
        changes => [
            'set /files/etc/apache2/apache2.conf/directive[self::directive="Timeout"]/arg 86400',
        ],
        notify  => Service['apache2'],
    }
}
