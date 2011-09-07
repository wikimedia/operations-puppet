# mediawiki.pp

class mediawiki::packages {
        package { wikimedia-task-appserver:
                ensure => latest;
        }
}

class mediawiki::sync {
        # Include this for syncinc mw installation
	# Include apache::apache-trigger-mw-sync to ensure that
	# the sync happens each time just before apache is started
	require mediawiki::packages

        exec { 	'mw-sync':
		command => "/usr/bin/sync-common",
                cwd => "/tmp",
                user => root,
                group => root,
                path => "/usr/bin:/usr/sbin",
                refreshonly => true,
                timeout => 60,
                logoutput => on_failure;
        }

}
