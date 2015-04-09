# role classes for dumps.wikimedia.org

class role::dumps {
    include ::dumps

    system::role { 'dumps': description => 'dumps.wikimedia.org' }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http'
    }

    $rsync_clients = hiera('dumps::rsync_clients')
    $rsync_clients_ferm = join($rsync_clients, ' ')

    ferm::service {'dumps-rsyncd':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve(($rsync_clients_ferm))",
    }

}

# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class role::dumps::zim {

    system::role { 'dumps::zim': description => 'ZIM dumps' }

    include ::dumps::zim
}

