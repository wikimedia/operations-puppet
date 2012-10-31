# manifests/role/zuul.pp

class role::zuul {

	system_role { "role::zuul": description => "Zuul gating system for Gerrit/Jenkins" }

	class labs {

		system_role { "role::zuul::labs": description => "Zuul on labs!" }

		# Setup the instance for labs usage
		zuulwikimedia::instance { "zuul-labs":
			jenkins_server => 'http://10.4.0.227:8080/ci',
			jenkins_user => 'zuul',
			gerrit_server => '10.4.0.227',
			gerrit_user => 'jenkins',
			# Not enabled yet but we need a pattern anyway:
			url_pattern => 'http://jenkinslogs.wmflabs.org/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
			status_url => 'http://integration.wmflabs.org/zuul/status',
		}

	} # /role::zuul::labs

	class production {

		system_role { "role::zuul::production": description => "Zuul on production" }

		zuulwikimedia::instance { "zuul-production":
			jenkins_server => 'https://integration.mediawiki.org/ci',
			jenkins_user => 'zuul-bot',
			gerrit_server => 'manganese.wikimedia.org',
			gerrit_user => 'jenkins-bot',
			# Not enabled yet but we need a pattern anyway:
			url_pattern => 'http://integration.mediawiki.org/zuulreport/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
			status_url => 'http://integration.mediawiki.org/zuul/status',
		}

	} # /role::zuul::production

} # /role::zuul
