# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class role::dumps::web::zim {

    system::role { 'dumps::web::zim': description => 'Web server for ZIM dumps' }

    include ::standard
    include ::profile::dumps::web::zim
    include ::base::firewall

    ferm::service { 'zim_dumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'zim_dumps_https':
        proto => 'tcp',
        port  => '443',
    }
}
