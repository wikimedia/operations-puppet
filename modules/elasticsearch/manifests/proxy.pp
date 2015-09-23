# == Class elasticsearch::proxy
# Sets up a simple nginx reverse proxy.
# This must be included on the same node as an elasticsearch server
#
# This depends on the ferm and nginx module's from WMF operations/puppet/modules.
#
class elasticsearch::proxy {
	class { '::nginx': }
	
	nginx::site { 'elasticsearch-proxy':
		content => template('nginx/sites/labs-es-proxy.erb')
	}

	ferm::service { 'http':
		proto => 'tcp',
		port => 80,
	}
}
