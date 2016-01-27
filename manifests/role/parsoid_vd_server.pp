# Testreduce server for aggregating and displaying visualdiff results

# This instantiates testreduce::server
class role::parsoid_vd_server {
    include ::testreduce
    include ::passwords::testreduce::mysql

    testreduce::server { 'parsoid-vd':
        instance_name => 'parsoid-vd',
        db_host => 'm5-master.eqiad.wmnet',
        db_name => 'testreduce_vd',
        db_user => 'testreduce',
        db_pass => $db_pass,
        webapp_port => 8010,
        coord_port => 8011,
    }

}
