# Class to clean out /var/cache/apt/archives
class apt::cleaner {
	cron {
		clean_apt_get_archives:
			command => 'apt-get clean',
			user => root,
			weekday => 'Wednesday';
	}

}
