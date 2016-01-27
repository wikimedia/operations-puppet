# Testreduce server for aggregating and displaying visualdiff results

# This instantiates testreduce::server
class role::parsoid_vd_server {
    include ::testreduce
    include ::passwords::testreduce::parsoid_vd

    # FIXME: Maybe rename db ot parsoid_vd?
    testreduce::server { 'parsoid-vd':
        instance_name => 'parsoid-vd',
        db_name => 'testreduce_vd',
        db_user => $db_user,
        db_pass => $db_name,
        webapp_port => 8010,
        coord_port => 8011,
    }

}
