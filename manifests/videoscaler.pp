# videoscaler.pp

# Virtual resource for the monitoring server
@monitor_group { "videoscaler": description => "transcode videos and create video thumbnails" }

class mediawiki::videoscaler {
	include imagescaler::packages,
		imagescaler::cron,
		imagescaler::files

	class {'jobrunner':
		type => "webVideoTranscode",
		timeout => 14400,
		extra_args => "-v 0"
    }
}
