# this file to be removed once we switch to role classes

class jobrunner::packages {

	package { [ 'wikimedia-job-runner' ]:
		ensure => latest;
	}

}
