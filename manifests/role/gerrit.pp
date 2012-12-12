# manifests/role/gerrit.pp

class role::gerrit {
	class labs {
		system_role { "role::gerrit::labs": description => "Gerrit in labs!" }

		class { "gerrit::instance":
			ircbot => false,
			db_host => "gerrit-db",
			host => "gerrit-dev.wmflabs.org",
			ssh_key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDIb6jbDSyzSD/Pw8PfERVKtNkXgUteOTmZJjHtbOjuoC7Ty6dbvUMX+45GedcD1wAYkWEY26RhI1lW2yEwKvh7VWkKixXqPNyrQGvI+ldjYEyWsGlEHCNqsh37mJD5K3cwr7X/PMaxzxh7rjTk4uRKjtiga9bz1vTDRDaNlXcj84kifsu7xmCY1E+OL4oqqy7b3SKhOpcpZc7n5GonfRSeon5uFHVUjoZ57xQ8x2736zbuLBwMRKtaB+V63cU9ArL90XdVrWfbjI4Fzfex4tBG9fOvt8lINR62cjH5Lova2kZ6VBeUnJYdZ8V1mOSwtITjwkE0K98FNZdqaANZAH7V",
			ssl_cert => "star.wmflabs",
			ssl_cert_key => "star.wmflabs",
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
			ssl_cert_key => "star.wikimedia.org",
			ssl_ca => "Equifax_Secure_CA",
			replication => {
				"formey" => {
				  "url" => 'gerritslave@formey.wikimedia.org:/var/lib/gerrit2/review_site/git/${name}.git',
				  "threads" => "4"
				},
				"github" => {
				  "url" => 'git@github.com:wikimedia/${name}',
				  "threads" => "4",
				  "authGroup" => "mediawiki-replication",
				  "push" => "+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*",
				  "isGithubRepo" => "true",
				},
				'gallium' => {
					'url' => 'gerritslave@gallium.wikimedia.org:/var/lib/git/${name}.git',
					'threads' => '4',
				},
			},
			smtp_host => "smtp.pmtpa.wmnet"
		}
	}

	class production::slave {
		system_role { "role::gerrit::slave": description => "Gerrit slave" }

		# It's a full slave, so install gerrit
		class { "gerrit::instance":
			slave => true,
			no_apache => true,
			db_host => "db1048.eqiad.wmnet",
			host => "formey.wikimedia.org",
		}

		# Slaves need to be able to recieve replication
		class { "gerrit::replicationdest":
			sshkey => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==",
			extra_groups => ["gerrit2"]
		}
	}

	# Include this role on *any* production host that wants to
	# receive gerrit replication
	class production::replicationdest {
		system_role { "role::gerrit::replicationdest": description => "Destination for gerrit replication" }

		class { "gerrit::replicationdest":
			sshkey => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw=="
		}
	}
}
