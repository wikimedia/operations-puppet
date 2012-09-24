# manifests/role/zuul.pp

class role::zuul {

	system_role { "role::zuul": description => "Zuul gating system for Gerrit/Jenkins" }

	class config {

		# Deploy Wikimedia Zuul configuration files.
		# Any changes made to them will trigger a reload of zuul via
		# the 'zuul-reload' exec provided by the 'zuul' puppet module.

		# Describe the behaviors and jobs
		file { "/etc/zuul/layout.yaml":
			ensure => 'present',
			source => 'puppet:///files/zuul/layout.yaml',
			notify => Exec['zuul-reload'],
		}

		# Logging configuration
		file { "/etc/zuul/logging.conf":
			ensure => 'present',
			source => 'puppet:///files/zuul/logging.conf',
			notify => Exec['zuul-reload'],
		}

	}

	class labs {

		system_role { "role::zuul::labs": description => "Zuul on labs!" }

		# Load Wikimedia zuul configuration:
		include role::zuul::config

		# Zuul needs an API key to interact with Jenkins:
		include passwords::misc::contint::jenkins
		$jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

		# Setup the instance for labs usage
		class { "::zuul":
			jenkins_server => 'http://10.4.0.227:8080/ci',
			jenkins_user => 'zuul',
			jenkins_apikey => $jenkins_apikey,
			gerrit_server => '10.4.0.227',
			gerrit_user => 'jenkins',
			# Not enabled yet but we need a pattern anyway
			url_pattern => 'http://jenkinslogs.wmflabs.org/{change.number}/{change.patchset}/{pipeline.name}/{job.name}/{build.number}',
		}

	} # /role::zuul::labs

} # /role::zuul
