class tor::base {
	package { [ "tor" ]:
		ensure => latest;
	}
}

