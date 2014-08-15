# syslog instance and configuration for applicationservers
class mediawiki::syslog( $log_aggregator ) {
    rsyslog::conf { 'mediawiki':
        content  => template('mediawiki/rsyslog.conf.erb'),
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
