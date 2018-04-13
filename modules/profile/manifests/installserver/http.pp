# Installs a web server for the install server
class profile::installserver::http {

    include install_server::web_server

    ferm::service { 'install_http':
        proto => 'tcp',
        port  => '(http https)'
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

