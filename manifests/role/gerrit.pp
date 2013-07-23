# manifests/role/gerrit.pp

class role::gerrit {
	class labs {
		system_role { 'role::gerrit::labs': description => 'Gerrit in labs!' }

		class { 'gerrit::instance':
			ircbot       => false,
			db_host      => 'gerrit-db',
			host         => 'gerrit-dev.wmflabs.org',
			ssh_key      => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDIb6jbDSyzSD/Pw8PfERVKtNkXgUteOTmZJjHtbOjuoC7Ty6dbvUMX+45GedcD1wAYkWEY26RhI1lW2yEwKvh7VWkKixXqPNyrQGvI+ldjYEyWsGlEHCNqsh37mJD5K3cwr7X/PMaxzxh7rjTk4uRKjtiga9bz1vTDRDaNlXcj84kifsu7xmCY1E+OL4oqqy7b3SKhOpcpZc7n5GonfRSeon5uFHVUjoZ57xQ8x2736zbuLBwMRKtaB+V63cU9ArL90XdVrWfbjI4Fzfex4tBG9fOvt8lINR62cjH5Lova2kZ6VBeUnJYdZ8V1mOSwtITjwkE0K98FNZdqaANZAH7V',
			ssl_cert     => 'star.wmflabs',
			ssl_cert_key => 'star.wmflabs',
		}
	}


	class production {
		system_role { 'role::gerrit::production': description => 'Gerrit master' }

		class { "gerrit::instance":
			ircbot        => true,
			db_host      => 'db1048.eqiad.wmnet',
			host         => 'gerrit.wikimedia.org',
			ssh_key      => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw==',
			ssl_cert     => 'gerrit.wikimedia.org',
			ssl_cert_key => 'gerrit.wikimedia.org',
			replication  => {
				# If adding a new entry, remember to add the fingerprint to gerrit2's known_hosts

				# FIXME remove it when all Jenkins jobs have been migrated to the new
				# directory /srv/ssd/gerrit defined in 'jenkins-gallium'
				'inside-wmf'             => {
					'url'                  => 'gerritslave@gallium.wikimedia.org:/var/lib/git/${name}.git',
					'threads'              => '4',
					'mirror'               => 'true',
				},
				# Start of Jenkins slaves
				# All entries should have the same target directory '/srv/ssd/gerrit'
				# since it is referenced in Jenkins jobs.
				'jenkins-gallium' => {
					'url'     => 'gerritslave@gallium.wikimedia.org:/srv/ssd/gerrit/${name}.git',
					'threads' => '4',
					'mirror'  => 'true',
				},
				'jenkins-lanthanum' => {
					'url'     => 'gerritslave@lanthanum.eqiad.wmnet:/srv/ssd/gerrit/${name}.git',
					'threads' => '4',
					'mirror'  => 'true',
				},
				# End of Jenkins slaves
				'gitblit'                => {
					'url'                   => 'gerritslave@antimony.wikimedia.org:/var/lib/git/${name}.git',
					'threads'               => '4',
					'authGroup'             => 'mediawiki-replication',
					'push'                  => '+refs/*:refs/*',
					'mirror'                => 'true',
				},
				'github'                 => {
					'url'                  => 'git@github.com:wikimedia/${name}',
					'threads'              => '4',
					'authGroup'            => 'mediawiki-replication',
					'push'                 => '+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*',
					'remoteNameStyle'      => 'dash',
					'mirror'               => 'true',
				},
				'github-puppet-cdh4'     => {
					'url'                  => 'git@github.com:wikimedia/puppet-cdh4',
					'threads'              => '1',
					'authGroup'            => 'mediawiki-replication',
					'push'                 => '+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*',
					'remoteNameStyle'      => 'dash',
					'mirror'               => 'true',
					'projects'             => 'operations/puppet/cdh4',
				},
				'github-puppet-jmxtrans' => {
					'url'                  => 'git@github.com:wikimedia/puppet-jmxtrans',
					'threads'              => '1',
					'authGroup'            => 'mediawiki-replication',
					'push'                 => '+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*',
					'remoteNameStyle'      => 'dash',
					'mirror'               => 'true',
					'projects'             => 'operations/puppet/jmxtrans',
				},
				'github-puppet-zookeeper' => {
					'url'                  => 'git@github.com:wikimedia/puppet-zookeeper',
					'threads'              => '1',
					'authGroup'            => 'mediawiki-replication',
					'push'                 => '+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*',
					'remoteNameStyle'      => 'dash',
					'mirror'               => 'true',
					'projects'             => 'operations/puppet/zookeeper',
				},
				'github-kraken' => {
					'url'                  => 'git@github.com:wikimedia/kraken',
					'threads'              => '1',
					'authGroup'            => 'mediawiki-replication',
					'push'                 => '+refs/heads/*:refs/heads/*
  push = +refs/tags/*:refs/tags/*',
					'remoteNameStyle'      => 'dash',
					'mirror'               => 'true',
					'projects'             => 'analytics/kraken',
				},
			},
			smtp_host => 'smtp.pmtpa.wmnet'
		}
	}

	# Include this role on *any* production host that wants to
	# receive gerrit replication
	class production::replicationdest {
		system_role { 'role::gerrit::replicationdest': description => 'Destination for gerrit replication' }

		class { 'gerrit::replicationdest':
			sshkey => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxOlshfr3UaPr8gQ8UVskxHAGG9xb55xDyfqlK7vsAs/p+OXpRB4KZOxHWqI40FpHhW+rFVA0Ugk7vBK13oKCB435TJlHYTJR62qQNb2DVxi5rtvZ7DPnRRlAvdGpRft9JsoWdgsXNqRkkStbkA5cqotvVHDYAgzBnHxWPM8REokQVqil6S/yHkIGtXO5J7F6I1OvYCnG1d1GLT5nDt+ZeyacLpZAhrBlyFD6pCwDUhg4+H4O3HGwtoh5418U4cvzRgYOQQXsU2WW5nBQHE9LXVLoL6UeMYY4yMtaNw207zN6kXcMFKyTuF5qlF5whC7cmM4elhAO2snwIw4C3EyQgw=='
		}
	}
}
