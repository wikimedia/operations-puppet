# This class is used to host the labtestwikitech database
#  locally on labtestweb2xxx.  We're trying to keep
#  random labtest things off of the prod databases.
class role::mariadb::labtestwikitech {

    system::role { 'mariadb::wikitech':
        description => 'Wikitech Database',
    }

    include ::standard
    include ::profile::mariadb::grants::core
    include ::profile::mariadb::monitor
    include ::profile::mariadb::labtestwikitech
}

