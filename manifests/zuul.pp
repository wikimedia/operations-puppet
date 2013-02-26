# manifests/zuul.pp

class zuulwikimedia {

	# Deploy wikimedia Zuul configuration files
	# Parameters are passed to the files templates
	define instance(
		$jenkins_server,
		$jenkins_user,
		$gerrit_server,
		$gerrit_user,
		$url_pattern,
		$status_url,
		$push_change_refs
	) {

			# Zuul needs an API key to interact with Jenkins:
			require passwords::misc::contint::jenkins
			$jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

			# Load class from the Zuul module:
			class { 'zuul':
				name => $name,
				jenkins_server   => $jenkins_server,
				jenkins_user     => $jenkins_user,
				jenkins_apikey   => $jenkins_apikey,
				gerrit_server    => $gerrit_server,
				gerrit_user      => $gerrit_user,
				url_pattern      => $url_pattern,
				status_url       => $status_url,
				push_change_refs => $push_change_refs,
			}

			# nagios/icinga monitoring
			monitor_service { 'zuul': description => 'zuul_service_running', check_command => 'nrpe_check_zuul' }

			# Deploy Wikimedia Zuul configuration files.

			# Describe the behaviors and jobs
			#
			# Conf file is hosted in integration/zuul-config git repo
			git::clone {
				"integration/zuul-config":
					directory => "/etc/zuul/wikimedia",
					owner => jenkins,
					group => jenkins,
					mode => 0775,
					origin => "https://gerrit.wikimedia.org/r/p/integration/zuul-config.git",
					branch => "master",
			}

			# Logging configuration
			# Modification done to this file can safely trigger a daemon
			# reload via the `zuul-reload` exect provided by the `zuul`
			# puppet module..
			file { "/etc/zuul/logging.conf":
				ensure => 'present',
				source => 'puppet:///files/zuul/logging.conf',
				notify => Exec['zuul-reload'],
			}
	}
}
