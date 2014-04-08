class diamond($statsd_host=undef, $statsd_port=undef) {

        package { 'python-diamond': ensure => present }
        ->
        file { '/etc/diamond/diamond.conf':
            ensure => file,
            content => template('diamond/diamond.conf.erb');
        }
        ~>
        service { 'diamond':
            ensure => running,
            enable => true,
            hasrestart => true,
            hasstatus => true,
        }
}
