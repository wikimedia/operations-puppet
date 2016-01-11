# Parsoid RT testing services
#
# This instantiates testreduce::server and testreduce::client services
class role::parsoid-rt {
    class {'::testreduce':
    }

    testreduce::server { 'parsoid-rt':
        instance_name => 'parsoid-rt',
        db_name => 'testreduce_0715',
        db_user => 'testreduce',
        db_pass => '',  # FIXME
    }

    file { '/srv/testreduce/parsoid-rt-client.rttest.localsettings.js':
        source => 'puppet:///modules/testreduce/parsoid-rt-client.rttest.localsettings.js',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['parsoid-rt-client'],
    }

    testreduce::client { 'parsoid-rt-client':
        instance_name => 'parsoid-rt-client',
    }
}
