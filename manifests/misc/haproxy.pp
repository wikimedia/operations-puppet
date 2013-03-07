# haproxy (RT-4660)

class misc::haproxy {

	system_role { 'misc::haproxy': description => 'haproxy host' }

	package { 'haproxy': ensure => present; }

	file { '/etc/haproxy/haproxy.cfg':
		ensure => present,
		mode => '0444',
		owner => root,
		group => root,
		source => "puppet:///files/misc/haproxy.cfg";

	}

	service { haproxy:
		ensure => running;
	}

	Package['haproxy'] -> File['/etc/haproxy/haproxy.cfg'] -> Service['haproxy']

}
