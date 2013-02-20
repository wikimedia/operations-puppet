class webtools::bastion {
	include webtools::libraries
	package { [
			'autoconf',
			'build-essential',
			'debhelper',
			'devscripts',
			'libtool',
		]: ensure => latest,
	}
}

