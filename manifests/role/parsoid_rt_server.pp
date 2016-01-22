# Parsoid RT testing services

# This instantiates testreduce::server
class role::parsoid_rt_server {
    include ::testreduce

    testreduce::server { 'parsoid-rt':
        instance_name => 'parsoid-rt',
        # FIXME: Maybe rename db to parsoid_rt
        # (or parsoid-rt if hyphens are allowed in db names)
        db_name => 'testreduce_0715',
        db_user => 'testreduce',
        db_pass => '',  # FIXME
    }

}
