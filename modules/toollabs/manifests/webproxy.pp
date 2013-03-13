# tools-webproxy

class tools::webproxy {
	package { [
			'libapache2-mod-proxy-html']:
		ensure => latest,
	}
}

