## triggers for syncing application servers
class applicationserver::sync {
	# Include this for syncinc mw installation
	# Include applicationserver::apache-trigger-mw-sync to ensure that
	# the sync happens each time just before apache is started
	require mediawiki::sync

	# Sync the server when we see apache is not running
	exec { 'apache-trigger-mw-sync':
		command => '/bin/true',
		notify => Exec['mw-sync'],
		unless => "/bin/ps -C apache2 > /dev/null"
	}

	# trigger sync, then start apache (if not running)
	Exec['apache-trigger-mw-sync'] -> Service['apache']
}