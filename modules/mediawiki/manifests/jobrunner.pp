class mediawiki::jobrunner (
	$run_jobs_enabled,
	$user = "apache",
	$type = "",
	$nice = 20,
	$script = "/usr/local/bin/jobs-loop.sh",
	$pid_file = "/var/run/mw-jobs.pid",
	$timeout = 300,
	$extra_args = "",
	$dprioprocs = 5,
	$iprioprocs = 5,
	$procs_per_iobound_type = 1
) {

	include mediawiki

	package { [ 'wikimedia-job-runner' ]:
		ensure => absent;
	}
	file {
		"/etc/init.d/mw-job-runner":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///modules/mediawiki/jobrunner/mw-job-runner.init";
	}
	file {
		"/etc/default/mw-job-runner":
			content => template("mediawiki/jobrunner/mw-job-runner.default.erb");
	}
	file {
		"/usr/local/bin/jobs-loop.sh":
			owner => root,
			group => root,
			mode => 0755,
			content => template("mediawiki/jobrunner/jobs-loop.sh.erb");
	}
	if $run_jobs_enabled == true {
		service {
			"mw-job-runner":
				require => [
					File[
						"/etc/default/mw-job-runner",
						"/etc/init.d/mw-job-runner",
						"/usr/local/bin/jobs-loop.sh"
					],
					Package[
						"wikimedia-task-appserver"
					],
				],
				subscribe => File[
					"/etc/default/mw-job-runner",
					"/etc/init.d/mw-job-runner",
					"/usr/local/bin/jobs-loop.sh"
				],
				hasstatus => false,
				pattern => $script,
				ensure => running;
		}
	} else {
		service { "mw-job-runner":
			hasstatus => false,
			pattern => $script,
			ensure => stopped;
		}
	}
}
