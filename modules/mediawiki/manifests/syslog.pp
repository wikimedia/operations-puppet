# syslog instance and configuration for applicationservers
class mediawiki::syslog( $apache_log_aggregator ) {
    rsyslog::rotated_log { '/var/log/apache2.log': }

    rsyslog::conf { 'mediawiki_apache':
        content  => template('mediawiki/apache/rsyslog.conf.erb'),
        priority => 40,
    }
}
