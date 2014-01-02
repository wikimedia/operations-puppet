# syslog instance and configuration for applicationservers
class applicationserver::syslog( $apache_log_aggregator ) {
    require base::remote-syslog

    file { '/etc/rsyslog.d/40-appserver.conf':
        ensure  => present,
        require => Package[rsyslog],
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('rsyslog/40-appserver.conf.erb'),
    }
    file { '/usr/local/bin/apache-syslog-rotate':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/scripts/apache-syslog-rotate',
    }
}
