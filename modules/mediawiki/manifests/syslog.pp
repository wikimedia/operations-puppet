class mediawiki::syslog {
    rsyslog::conf { 'mediawiki':
        source   => 'puppet:///modules/mediawiki/rsyslog.conf',
        priority => 40,  # before 50-default.conf
    }

    file { '/etc/logrotate.d/mediawiki_apache':
        source => 'puppet:///modules/mediawiki/logrotate.d_mediawiki_apache',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Rsyslog::Conf['mediawiki'],
    }
}
