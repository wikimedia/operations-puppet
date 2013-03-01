

class tools::login {
	file { "/etc/sudoers.d/tools-login":
		owner => root,
		group => root,
		mode => 0440,
		content => "#include /data/project/.system/sudoers\n",
		ensure => present;
	}
}

