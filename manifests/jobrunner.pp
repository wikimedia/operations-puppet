class jobrunner::packages {

	package { [ 'wikimedia-job-runner' ]:
		ensure => latest;
	}

	if ($::realm == 'labs') and ($::instanceproject == 'deployment-prep') {
		require labs::umount_vdb

		mount { "/tmp":
			device => "/dev/vdb",
			name   => "/tmp",
			ensure => mounted;
		}

	}

}
