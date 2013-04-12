# vim: noet
class role::jenkins::master::production {

	system_role { 'role::zuul::production': description => 'Jenkins master on production' }

	file { '/srv/ssd/jenkins':
		ensure => 'directory',
		owner  => 'jenkins',
		group  => 'jenkins',
		mode   => '2775',  # group sticky bit
		require => Mount['/srv/ssd'],
	}

	file { '/srv/ssd/jenkins/workspace':
		ensure => 'directory',
		owner  => 'jenkins',
		group  => 'jenkins',
		mode   => '0775',
		require => [
			File['/srv/ssd/jenkins'],
		],
	}

}
