# misc/captcha.pp

# Puppet class regrouping anything that is related to Captcha
# generation
class misc::captcha {

	class packages {

		package { [
			"python-imaging",
			"wamerican",
			]: ensure => present
		}
	}

}
