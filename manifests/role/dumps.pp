# role classes for dumps.wikimedia.org

class role::dumps {
    include ::dumps

    system::role { 'dumps': description => 'dumps.wikimedia.org' }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http'
    }

    ferm::service {'dumps-rsyncd':
        port   => '873',
        proto  => 'tcp',
        srange => $dumps_rsync_clients_all,
    }

}
