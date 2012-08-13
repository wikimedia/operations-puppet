## triggers for syncing application servers

# ensure that the sync happens each time before apache is started
class applicationserver::sync {
	## TODO: change mediawiki_new to just mediawiki after full transition to module
	Class["mediawiki_new::sync"] -> Class["applicationserver::sync"]
	Class["applicationserver::service"] -> Class["applicationserver::sync"]

	# Sync the server when we see apache is not running
	exec { 'apache-trigger-mw-sync':
		command => '/bin/true',
		notify => Exec['mw-sync'],
		unless => "/bin/ps -C apache2 > /dev/null"
	}

	# trigger sync, then start apache (if not running)
	Exec['apache-trigger-mw-sync'] -> Service['apache']
}