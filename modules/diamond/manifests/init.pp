class diamond($statsd_host=undef, $statsd_port=undef) {

        package { 'python-diamond': ensure => present }

        file { '/etc/diamond/diamond.conf':
            content => template('diamond/diamond.conf.erb');
            require => Package['python-diamond'],
        }

        service { 'diamond':
            ensure => running,
            enable => true,
            hasrestart => true,
            hasstatus => true,
            subscribe => File['/etc/diamond/diamond.conf'],
        }
}
