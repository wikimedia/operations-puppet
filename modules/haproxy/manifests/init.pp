# Class haproxy
# Installs haproxy and ensures that it is running.
class haproxy{
    system::role { 'haproxy': description => 'haproxy host' }

    package { 'haproxy':
		ensure => present,

    }
	file { '/etc/haproxy/haproxy.cfg':
        ensure  => present,
		mode    => '0444',
		owner   => 'root',
		group   => 'root',
		content => template('haproxy/haproxy.erb'),
		notify  => Service['haproxy'],
	}

	service { 'haproxy':
		ensure     => running,
		enable     => true,
		hasstatus  => true,
		hasrestart => true,
	}
}
