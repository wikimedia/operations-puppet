class profile::mariadb::monitor {

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',
    }
}
