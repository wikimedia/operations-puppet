# manifests/zuul.pp

class zuulwikimedia {

	# Deploy wikimedia Zuul configuration files
	# Parameters are passed to the files templates
	define instance(
		$jenkins_server,
		$jenkins_user,
		$gerrit_server,
		$gerrit_user,
		$url_pattern
	) {

			# Zuul needs an API key to interact with Jenkins:
			require passwords::misc::contint::jenkins
			$jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

			# Load class from the Zuul module:
			class { 'zuul':
				name => $name,
				jenkins_server => $jenkins_server,
				jenkins_user   => $jenkins_user,
				jenkins_apikey => $jenkins_apikey,
				gerrit_server  => $gerrit_server,
				gerrit_user    => $gerrit_user,
				url_pattern    => $url_pattern,
			}

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
}
