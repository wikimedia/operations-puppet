class jobrunner {

	class packages {
		package { [ 'wikimedia-job-runner' ]:
			ensure => latest;
		}
	}

	# labs specific
	class labs {
		if ($::realm == 'labs') and ($::instanceproject == 'deployment-prep') {

			require labs::umount_vdb

			mount { "/tmp":
				device => "/dev/vdb",
				name   => "/tmp",
				ensure => mounted;
			}

		}
	}

}
