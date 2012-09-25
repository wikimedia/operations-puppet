# manifests/role/gerrit.pp

class role::gerrit {

	system_role { "role::gerrit": description => "Gerrit installation" }

	class labs {
		system_role { "role::gerrit::production": description => "Gerrit in labs!" }

		class { "gerrit::instance":
			ircbot => false,
			db_host => "gerrit-db",
			host => "gerrit-dev.wmflabs.org",
			ssh_key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDIb6jbDSyzSD/Pw8PfERVKtNkXgUteOTmZJjHtbOjuoC7Ty6dbvUMX+45GedcD1wAYkWEY26RhI1lW2yEwKvh7VWkKixXqPNyrQGvI+ldjYEyWsGlEHCNqsh37mJD5K3cwr7X/PMaxzxh7rjTk4uRKjtiga9bz1vTDRDaNlXcj84kifsu7xmCY1E+OL4oqqy7b3SKhOpcpZc7n5GonfRSeon5uFHVUjoZ57xQ8x2736zbuLBwMRKtaB+V63cU9ArL90XdVrWfbjI4Fzfex4tBG9fOvt8lINR62cjH5Lova2kZ6VBeUnJYdZ8V1mOSwtITjwkE0K98FNZdqaANZAH7V",
			ssl_cert => "star.wmflabs.org",
			ssl_ca => "wmf-labs"
		}
	}

	# Install of Gerrit for Jenkins developpement
	class labs::jenkins {
		system_role { "role::gerrit:labs::jenkins": description => "Gerrit on Jenkins dev instance" }

		class { "gerrit::instance":
			ircbot => false,
			db_host => localhost,
			host => "integration.wmflabs.org",
			ssh_key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC920PnWt3nTsGy7C/A9evATC2HHB4nelBS//LqquEKGfwRuLvNkQdxymhJgfwmTR692OcYcVToJnUYLKrhiGgS6I0nOjVV77xpB/ckymOqbf4B3LmYuEi2MmtyoCb6RB7tjBcoAA/7CtK2WHKdUz1mRhEbPA16eD99PhVftIvu/4pNfvcTpZ/kTP5FmmSqoeHPGWZI+meWlL1BRp2lpF7Xg2ahJHBU6Qs+HDh6LNJCtVrfzz9xa+dLtFxBXQTdQwIuBw9Pn4mNdzBDtMG32lwtp7qpojqRYqCjpiJu9SkI1jmjmqIn6MdnoS+2n1OskpX3cVJDGlCcjfOoCQfOFIpL",
			ssl_cert => "star.wmflabs.org",
			ssl_ca => "wmf-labs"
		}
	}

	class production {
		system_role { "role::gerrit::production": description => "Gerrit master" }

		class { "gerrit::instance":
			ircbot => true,
			db_host => "db1048.eqiad.wmnet",
			host => "gerrit.wikimedia.org",
			ssh_key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==",
			ssl_cert => "star.wikimedia.org",
			ssl_ca => "Equifax_Secure_CA",
			replication => {
				"formey" => {
				  "url" => 'gerrit2@formey.wikimedia.org:/var/lib/gerrit2/review_site/git/${name}.git',
				  "threads" => "4"
				}
			},
			smtp_host => "smtp.pmtpa.wmnet"
		}
	}

	class production::slave {
		system_role { "role::gerrit::slave": description => "Gerrit slave" }

		class { "gerrit::instance":
			slave => true,
			no_apache => true,
			db_host => "db1048.eqiad.wmnet",
			host => "formey.wikimedia.org",
			ssh_key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw=="
		}
	}

}
