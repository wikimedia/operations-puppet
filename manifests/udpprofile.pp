class udpprofile::collector {

	package { [ 'udpprofile' ]:
		ensure => latest;
	}

	service { 
		udpprofile:
			require => Package[ 'udpprofile' ],
			ensure => running;
	}

}
