# This class is used to host the labtestwikitech database
#  locally on labtestweb2xxx.  We're trying to keep
#  random labtest things off of the prod databases.
#  This database is currently hosted on clouddb2001-dev.codfw.wmnet # T233236
class role::mariadb::labtestwikitech {

    system::role { 'mariadb::wikitech':
        description => 'Wikitech Database',
    }

    include ::profile::standard
    include ::profile::mariadb::grants::core
    include ::profile::mariadb::monitor
    include ::profile::mariadb::labtestwikitech
}

