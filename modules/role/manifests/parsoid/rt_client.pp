# This instantiates testreduce::client
class role::parsoid::rt_client {
    include ::testreduce

    file { '/srv/deployment/parsoid/deploy/src/tests/testreduce/parsoid-rt-client.rttest.localsettings.js':
        content => template('testreduce/parsoid-rt-client.rttest.localsettings.js.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['parsoid-rt-client'],
    }

    testreduce::client { 'parsoid-rt-client':
        instance_name => 'parsoid-rt-client',
        parsoid_port  => hiera('testreduce::parsoid_port'),
    }
}
