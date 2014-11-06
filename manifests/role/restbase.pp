# == Class role::restbase
#

class role::restbase::labs::otto-cass {
	system::role{ 'restbase': description => 'restbase labs::otto-cass' }

	class '::restbase': {
		case $::realm {
			'labs': {
				seeds => ["10.68.17.68","10.68.17.60","10.68.17.71"],
				cassandra_password => 'test', # $::passwords::cassandra::otto-cass::password,
				cassandra_password => 'test', # $::passwords::cassandra::otto-cass::password,
			}
			#'production': {
			#	$wikistats_host = 'wikistats.wikimedia.org'
			#	seeds => ,
			#	cassandra_password => $::passwords::cassandra::otto-cass::password,
			#	cassandra_password => $::passwords::cassandra::otto-cass::password,
			#}
			default: {
				fail('unknown realm, should be labs or production')
			}
		}
	}
}
