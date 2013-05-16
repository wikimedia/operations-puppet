# applicationserver::config

class applicationserver::config::base {
	# Other classes can depend on this to ensure all configuration
	# is complete
	if $::realm == 'labs' {
		file { '/usr/local/apache':
			ensure => link,
			target => '/data/project/apache',
      # Create it before wikimedia-task-appserver attempts
      # to create /usr/local/apache/common
      before => Package['wikimedia-task-appserver'],
		}
	}
}
