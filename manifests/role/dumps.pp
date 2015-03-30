# role classes for dumps.wikimedia.org

class role::dumps {
    include ::dumps

    system::role { 'dumps': description => 'dumps.wikimedia.org' }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http'
    }

}

# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class role::dumps::zim }

    system::role { 'dumps::zim': description => 'ZIM dumps' }

    include ::dumps::zim
}

