# Generic Server
#
# filtertags: labs-project-servermon labs-project-monitoring
class role::mariadb {

    system::role { 'mariadb':
        description => 'database server',
    }

    include ::standard
    include ::mariadb
}
