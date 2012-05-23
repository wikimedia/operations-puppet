class labs {

	# Nova mounts /dev/vdb on /mnt by default.
	# This class let us easily umount it
	class umount_vdb {
		if( $realm == 'labs' ) { # safeguard
			mount { "/mnt":
				device => '/dev/vdb',
				name => '/mnt',
				ensure => absent;
			}
		}
	}

}
