class jobrunner::packages {

	package { [ 'wikimedia-job-runner' ]:
		ensure => latest;
	}

}
