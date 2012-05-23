class jobrunner::packages {

	package { [ 'wikimedia-job-runner' ]:
		ensure => latest;
	}

	if ($::realm == 'labs') && ($::instanceproject == 'deployment-prep') {
		require labs::umount_vdb

		mount { "/tmp":
			device => "/dev/vdb",
			name   => "/tmp",
			ensure => mounted;
		}

	}

}
