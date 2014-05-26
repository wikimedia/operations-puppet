# syslog instance and configuration for applicationservers
class mediawiki::syslog( $apache_log_aggregator ) {
    file { '/etc/logrotate.d/mediawiki_apache':
        source  => 'puppet:///modules/mediawiki/logrotate.d_mediawiki_apache',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    rsyslog::conf { 'mediawiki_apache':
        content  => template('mediawiki/apache/rsyslog.conf.erb'),
        priority => 40,
    }
}
