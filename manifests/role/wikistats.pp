# wikistats host role class
class role::wikistats {

	# config - labs vs. production
	case $::realm {
		labs: {
			$wikistats_host = 'wikistats.wmflabs.org'
			$wikistats_ssl_cert = '/etc/ssl/certs/star.wmflabs.org.pem'
			$wikistats_ssl_key = '/etc/ssl/private/star.wmflabs.org.key'
		}
		production: {
			$wikistats_host = 'wikistats.wikimedia.org'
			$wikistats_ssl_cert = '/etc/ssl/certs/star.wikimedia.org.pem'
			$wikistats_ssl_key = '/etc/ssl/private/star.wikimedia.org.key'
		}
		default: {
			fail('unknown realm, should be labs or production')
		}
	}

	# main
	class { 'misc::wikistats': }
	class { 'misc::wikistats::web': wikistats_host => $wikistats_host, wikistats_ssl_cert => $wikistats_ssl_cert, wikistats_ssl_key => $wikistats_ssl_key  }
	class { 'misc::wikistats::updates': }

}
