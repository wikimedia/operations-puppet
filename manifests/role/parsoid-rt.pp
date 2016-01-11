# Parsoid RT testing services
#
# This instantiates testreduce::server and testreduce::client services
class role::parsoid-rt {
	testreduce::server {
		instance_name => 'parsoid-rt',
        db_name => 'testreduce_0715',
        db_user => 'testreduce',
        db_pass => '',  # FIXME
    }

	file { '/etc/init/${instance_name}.conf':
		source => "puppet:///modules/testreduce/rttest.localsettings.js",
		owner  => 'root',
		group  => 'root',
		mode   => '0444',
		notify => Service['parsoid-rt-client'],
	}

	testreduce::client {
		instance_name => 'parsoid-rt-client',
    }
}
