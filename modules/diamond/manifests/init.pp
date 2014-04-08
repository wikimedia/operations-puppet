class diamond(
        $statsd_host='127.0.0.1',
        $statsd_port='8125'
){
        package { 'python-diamond':
                ensure => present
        }

        file { '/etc/diamond/diamond.conf':
            content => template('diamond/diamond.conf.erb'),
            require => Package['python-diamond'],
        }

        service { 'diamond':
            ensure     => running,
            enable     => true,
            hasrestart => true,
            hasstatus  => true,
            subscribe  => File['/etc/diamond/diamond.conf'],
        }
}
