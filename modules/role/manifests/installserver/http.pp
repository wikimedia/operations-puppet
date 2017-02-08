# Installs a web server for the install server
class role::installserver::http {

    system::role { 'role::installserver::http':
        description => 'WMF install HTTP server',
    }

    include install_server::web_server

    include ::standard
    include ::base::firewall

    ferm::service { 'install_http':
        proto => 'tcp',
        port  => '(http https)'
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

