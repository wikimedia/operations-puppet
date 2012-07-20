# FIXME: move to app server role class, remove this file.

class jobrunner::packages {

	package { [ 'wikimedia-job-runner' ]:
		ensure => latest;
	}

}
