# visual diff server for displaying/generating diffs
# for a specific test item

# This instantiates visualdiff::server
class role::parsoid::visualdiff_server {
    include ::visualdiff

    visualdiff::server { 'diffserver':
        instance_name => 'diffserver',
        webapp_port   => 8012,
    }
}
