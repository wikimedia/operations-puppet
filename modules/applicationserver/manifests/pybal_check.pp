# creates pybal-check system user
class applicationserver::pybal_check {
	$authorized_key = 'command="uptime; touch /var/tmp/pybal-check.stamp" ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwyiL/ImTNOjoP/8k1UFQRM9pcspHp3yIsH/8TYXH/HJ1rQVjMleq6IQ6ZwAXhKfw/v1xV28SbkctB8pISZoR4rcCqOIN+osXkCB419JydCEb5abPS4mB5Gkn2bZAF43DGr5kaW+HYIsgtZ+QEC+nS4j3NA/Bjb7lAbHUtHVuC6BCOaZfGf+Q2FO4Z6xC7zc/1ngaDgvrXYzyCvXzTAQmcZH0d2/GoS1DQoLdLzqu66aZK1dmn9TAHV4a3R4gp7El7OzVHqDp1E6y0sopd+qKNAw/3GgXC91XJ3XO22h+ZnVovIpIS01CJ6GiBig/55Xrh//9Wuw5GFQuCptYbPQr4Q== root@lvs4'

	# Create pybal-check user account	
	systemuser { "pybal-check": name => "pybal-check", home => "/var/lib/pybal-check", shell => "/bin/sh" }

	file {
		"/var/lib/pybal-check/.ssh":
			require => Systemuser["pybal-check"],
			owner => "pybal-check",
			group => "pybal-check",
			mode => 0550,
			ensure => directory;
		"/var/lib/pybal-check/.ssh/authorized_keys":
			owner => "pybal-check",
			group => "pybal-check",
			mode => 0440,
			content => $authorized_key;
	}
}