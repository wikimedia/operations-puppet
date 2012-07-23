# videoscaler.pp

# Virtual resource for the monitoring server
@monitor_group { "videoscaler": description => "transcode videos and create video thumbnails" }

class videoscaler::cron {
	include imagescaler::cron
}

class videoscaler::packages {
	include imagescaler::packages
}

class videoscaler::files {

	include imagescaler::files
	class {'jobrunner':
		type => "webVideoTranscode",
		timeout => 14400,
		extra_args => "-v 0"
    }
}
