# Parsoid RT testing services

# This instantiates testreduce::server
class role::parsoid-rt-server {
    class {'::testreduce':
    }

    testreduce::server { 'parsoid-rt':
        instance_name => 'parsoid-rt',
        db_name => 'testreduce_0715',
        db_user => 'testreduce',
        db_pass => '',  # FIXME
    }

}
