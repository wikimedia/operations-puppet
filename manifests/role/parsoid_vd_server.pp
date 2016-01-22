# Testreduce server for aggregating and displaying visualdiff results

# This instantiates testreduce::server
class role::parsoid_vd_server {
    include ::testreduce

    testreduce::server { 'parsoid-vd':
        instance_name => 'parsoid-vd',
        # FIXME: Should we use parsoid_vd ?
        # (or parsoid-vd if hyphens are allowed in db names)
        db_name => 'testreduce_vd',
        db_user => 'testreduce',
        db_pass => '',  # FIXME
        webapp_port => 8010,
        coord_port => 8011,
    }

}
