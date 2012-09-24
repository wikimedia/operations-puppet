# manifests/role/zuul.pp

class role::zuul {

	system_role { "role::zuul": description => "Zuul gating system for Gerrit/Jenkins" }

	include passwords::misc::contint::jenkins::zuul_user_apikey
	$jenkins_apikey = $passwords::misc::contint::jenkins::zuul_user_apikey

	class labs {
		system_role { "role::zuul::labs": description => "Zuul on labs!" }

		class { "zuul":
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
