# timedmediahandler.pp

# Virtual resource for the monitoring server
@monitor_group { "timedmediahandler": description => "TimedMediaHandler Transcoding" }

class timedmediahandler::packages {
	if ( $lsbdistcodename == "lucid" ) {
        apt::pparepo {
            "timedmediahandler": repo_string => "j/timedmediahandler",
                                 apt_key => "01975EF3",
                                 dist => "lucid",
                                 ensure => "present"
        }
        package { 
            [ "php5-cli", "php-pear", "php5-common", "php5-curl", "php5-mysql",
              "imagemagick",
              "ffmpeg",
              "ffmpeg2theora" ]:
            ensure => latest,
            require => Apt::Pparepo["timedmediahandler"];
        }
    }
}

class timedmediahandler::files {

	if ( $lsbdistcodename == "lucid" ) {
		file {
            "/etc/init/timedmediahandler.conf":
                owner => root,
                group => root,
                mode => 0444,
                notify => Service["timedmediahandler"],
				require => Package["timedmediahandler"];
                source => "puppet:///files/upstart/timedmediahandler.conf";
			"/etc/wikimedia-image-scaler":
				content => "The presence of this file alters the apache configuration, to be suitable for transcoding.",
				owner => root,
				group => root,
				mode => 0644;
		}
	}

}

class timedmediahandler::service {
	service { "timedmediahandler":
		enable => "true",
		ensure => running,
		require => [Package["timedmediahandler"],
                    Upstart_job["timedmediahandler"]];
	}
	upstart_job {
        "timedmediahandler": require => Package["timedmediahanlder"], install => "true" 
    }
}
