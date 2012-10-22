class mediawiki_new::jobrunner (
	$user = "apache",
	$type = "",
	$nice = 20,
	$script = "/usr/local/bin/jobs-loop.sh",
	$pid_file = "/var/run/mw-jobs.pid",
	$timeout = 300,
	$extra_args = "",
	$procs = 5
) {

## TODO: get rid of this awfulness after full transition to module/precise
	if ( $::lsbdistcodename == "precise" ) {
	include mediawiki_new
	} else {
	include mediawiki::packages
	}

	package { [ 'wikimedia-job-runner' ]:
		ensure => absent;
	}
	file {
		"/etc/init.d/mw-job-runner":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///modules/mediawiki_new/jobrunner/mw-job-runner.init";
	}
	file {
		"/etc/default/mw-job-runner":
			content => template("mediawiki_new/jobrunner/mw-job-runner.default.erb");
	}
	file {
		"/usr/local/bin/jobs-loop.sh":
			owner => root,
			group => root,
			mode => 0755,
			content => template("mediawiki_new/jobrunner/jobs-loop.sh.erb");
	}
	service {
		"mw-job-runner":
			require => [
				File[
					"/etc/default/mw-job-runner",
					"/etc/init.d/mw-job-runner",
					"/usr/local/bin/jobs-loop.sh"
				],
				Package[
					"wikimedia-job-runner",
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
}
