# This class defines the packages which should be present
# on all webtools hosts.
class webtools::libraries {
	package { [
			'libdbd-sqlite3-perl',
			'liburi-perl',
			'libhtml-parser-perl',
			'libwww-perl',
		]: ensure => latest,
	}
}

