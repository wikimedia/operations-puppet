# manifests/role/zuul.pp

class role::zuul {

	system_role { "role::zuul": description => "Zuul gating system for Gerrit/Jenkins" }

	class labs {

		system_role { "role::zuul::labs": description => "Zuul on labs!" }

		include contint::proxy_zuul

		# Setup the instance for labs usage
		zuulwikimedia::instance { "zuul-labs":
			jenkins_server => 'http://10.4.0.172:8080/ci',
			jenkins_user => 'zuul',
			gerrit_server => '10.4.0.172',
			gerrit_user => 'jenkins',
			# Not enabled yet but we need a pattern anyway:
			#url_pattern => 'http://jenkinslogs.wmflabs.org/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
			url_pattern => 'http://integration.wmflabs.org/ci/job/{job.name}/{build.number}/console',
			status_url => 'http://integration.wmflabs.org/zuul/status',
			git_dir => '/var/lib/zuul/git',
			push_change_refs => false
		}

	} # /role::zuul::labs

	class production {

		# We will receive replication of git bare repositories from Gerrit
		include role::gerrit::production::replicationdest
		include contint::proxy_zuul

		file { "/var/lib/git":
			ensure => 'directory',
			owner => 'gerritslave',
			group => 'root',
			mode => '0755',
		}

		system_role { "role::zuul::production": description => "Zuul on production" }

		# TODO: should require Mount['/srv/ssd']
		zuulwikimedia::instance { "zuul-production":
			jenkins_server => 'https://integration.wikimedia.org/ci',
			jenkins_user => 'zuul-bot',
			gerrit_server => 'manganese.wikimedia.org',
			gerrit_user => 'jenkins-bot',
			# Not enabled yet but we need a pattern anyway:
			#url_pattern => 'https://integration.wikimedia.org/zuulreport/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
			url_pattern => 'https://integration.wikimedia.org/ci/job/{job.name}/{build.number}/console',
			status_url => 'https://integration.wikimedia.org/zuul/',
			git_dir => '/srv/ssd/zuul/git',
			push_change_refs => false
		}

	} # /role::zuul::production

} # /role::zuul
