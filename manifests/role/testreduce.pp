# == Class: role::testreduce
#
# Parsoid round-trip test result aggregator.
#
class role::testreduce {
    class { 'testreduce':
        db_name => 'testreduce_0715',
        db_user => 'testreduce',
        db_pass => '',  # FIXME
    }
}
