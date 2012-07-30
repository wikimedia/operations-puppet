# role/bastion.pp

class role::bastion {

	class common {
		require mysql::client
		include sudo::appserver

		# Bastion is used to regenerate our captchas:
		include misc::captcha

		package { "irssi":
			ensure => absent;
			"traceroute-nanog":
				ensure => absent;
			"traceroute":
				ensure =>latest;
		}
	}

	class production {
		include role::bastion::common
		system_role { "role::bastion::production": description => "Bastion" }

	}

	class labs {
		include role::bastion::common
		system_role { "role::bastion::labs": description => "Bastion" }

		package { [
			'joe',
			'nano',
			'tree',
			]: ensure=>present
		}
	}
}

