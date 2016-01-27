# Parsoid RT testing services

# This instantiates testreduce::server
class role::parsoid_rt_server {
    include ::testreduce
    include ::passwords::testreduce::parsoid_rt

    # FIXME: Maybe rename db to parsoid_rt?
    testreduce::server { 'parsoid-rt':
        instance_name => 'parsoid-rt',
        db_name => 'testreduce_0715',
        db_user => $db_user,
        db_pass => $db_pass,
    }

}
