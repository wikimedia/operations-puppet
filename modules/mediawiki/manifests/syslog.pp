# syslog instance and configuration for applicationservers
class mediawiki::syslog( $apache_log_aggregator ) {
    include ::rsyslog

    rsyslog::conf { 'mediawiki_apache':
        content  => template('mediawiki/apache/rsyslog.conf.erb'),
        priority => 40,
        require  => File['/usr/local/bin/apache-syslog-rotate'],
    }
}
