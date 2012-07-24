class jobrunner::packages {

	package { [ 'wikimedia-job-runner' ]:
		ensure => latest;
	}

}

class jobrunner::files {

	if $jobrunner_user == undef {
		$jobrunner_user = "apache"
	}
	if $jobrunner_type == undef {
		$jobrunner_type = ""
	}
	if $jobrunner_nice == undef {
		$jobrunner_nice = 20
	}
	if $jobrunner_script == undef {
		$jobrunner_script = "/usr/local/bin/jobs-loop.sh"
	}
	if $jobrunner_pid_file == undef {
		$jobrunner_pid_file = "/var/run/mw-jobs.pid"
	}
	if $jobrunner_timeout == undef {
		$jobrunner_timeout = 300
	}
	if $jobrunner_extra_args == undef {
		$jobrunner_extra_args = ""
	}
	file {
		"/etc/init.d/mw-job-runner":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/jobrunner/mw-job-runner.init";
	}
	file {
		"/etc/default/mw-job-runner":
			content => template("jobrunner/mw-job-runner.default.erb");
	}
	file {
		"/usr/local/bin/jobs-loop.sh":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/jobrunner/jobs-loop.sh";
	}
	service {
		"mw-job-runner":
			require => [
				File[
					"/etc/default/mw-job-runner",
					"/etc/init.d/mw-job-runner",
					"/usr/local/bin/jobs-loop.sh",
				],
			],
			hasstatus => false,
			pattern => $jobrunner_pid_file,
			ensure => running;
	}

}
