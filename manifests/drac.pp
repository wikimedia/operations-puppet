class drac::management {

	package { [ 'python-paramiko' ]:
		ensure => latest;
	}

	file {
		"/usr/local/sbin/drac":
			owner => root,
			group => root,
			mode  => 0755,
			require => Package[ 'python-paramiko' ],
			source => "puppet:///files/drac/drac.py";
	}

}
