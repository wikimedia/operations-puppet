# vim: noet
class role::jenkins::master::production {

	system_role { 'role::jenkins::master::production': description => 'Jenkins master on production' }

	file { '/srv/ssd/jenkins':
		ensure  => 'directory',
		owner   => 'jenkins',
		group   => 'jenkins',
		mode    => '2775',  # group sticky bit
		require => Mount['/srv/ssd'],
	}

	file { '/srv/ssd/jenkins/workspace':
		ensure  => 'directory',
		owner   => 'jenkins',
		group   => 'jenkins',
		mode    => '0775',
		require => [
			File['/srv/ssd/jenkins'],
		],
	}

	contint::tmpfs { 'tmpfs for jenkins CI master':
		user        => 'jenkins',
		group       => 'jenkins',
		mount_point => '/var/lib/jenkins/tmpfs',
		size        => '512M',
	}

	# Ganglia monitoring for Jenkins
	# The upstream module is named 'jenkins' which conflicts with python-jenkins
	# since gmond will lookup the 'jenkins' python module in the system path
	# before the module path.
	# See: https://github.com/ganglia/monitor-core/issues/111

	file { '/usr/lib/ganglia/python_modules/jenkins.py':
		ensure => absent,
	}
	file { '/usr/lib/ganglia/python_modules/gmond_jenkins.py':
			source => 'puppet:///files/ganglia/plugins/jenkins.py',
			owner  => 'root',
			group  => 'root',
			mode   => '0444',
			notify => Service[gmond],
	}

	file { '/etc/ganglia/conf.d/jenkins.pyconf':
		ensure => absent,
	}
	file { '/etc/ganglia/conf.d/gmond_jenkins.pyconf':
			source => 'puppet:///files/ganglia/plugins/jenkins.pyconf',
			owner  => 'root',
			group  => 'root',
			mode   => '0444',
			notify => Service[gmond],
	}

}

class role::jenkins::slave::production {

	system_role { 'role::jenkins::slave::production': description => 'Jenkins slave on production' }

	class { 'jenkins::slave':
		ssh_authorized_key => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw==',
		ssh_key_name       => 'jenkins@gallium',
		# Lamely restrict to master which is gallium
		ssh_key_options    => [ 'from="208.80.154.135"' ],
		user               => 'jenkins-slave',
		workdir            => '/srv/ssd/jenkins-slave',
		require            => Mount['/srv/ssd'],
	}

	contint::tmpfs { 'tmpfs for jenkins CI slave':
		user        => 'jenkins-slave',
		group       => 'jenkins-slave',
		mount_point => '/var/lib/jenkins-slave/tmpfs',
		size        => '128M',
	}

}
