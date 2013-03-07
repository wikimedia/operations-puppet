# haproxy (RT-4660)

class misc::haproxy($config_file = undef) {

	system_role { 'misc::haproxy': description => 'haproxy host' }

	package { 'haproxy': ensure => present; }

	service { haproxy:
		ensure  => running,
		require => Package['haproxy'],
	}

	if ($config_file) {
		file { '/etc/haproxy/haproxy.cfg':
			ensure => present,
			mode   => '0444',
			owner  => 'root',
			group  => 'root',
			source => $config_file,
			notify => Service['haproxy'],
		}
	}
}
