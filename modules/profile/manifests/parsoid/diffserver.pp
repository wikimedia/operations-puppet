# visual diff server for displaying/generating diffs
# for a specific test item

# This instantiates visualdiff::server
class profile::parsoid::diffserver {
    include ::visualdiff

    visualdiff::server { 'diffserver':
        instance_name => 'diffserver',
        webapp_port   => 8012,
    }

    base::service_auto_restart { 'diffserver': }
}
