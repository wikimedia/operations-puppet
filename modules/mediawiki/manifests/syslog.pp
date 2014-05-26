# syslog instance and configuration for applicationservers
class mediawiki::syslog( $apache_log_aggregator ) {
    include ::rsyslog

    file { '/usr/local/bin/apache-syslog-rotate':
        source => 'puppet:///mediawiki/apache/apache-syslog-rotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

   rsyslog::conf { 'mediawiki_apache':
        content  => template('mediawiki/apache/rsyslog.conf.erb'),
        priority => 40,
        require  => File['/usr/local/bin/apache-syslog-rotate'],
    }
}
