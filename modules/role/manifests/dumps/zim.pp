# ZIM dumps - https://en.wikipedia.org/wiki/ZIM_%28file_format%29
class role::dumps::zim {

    system::role { 'dumps::zim': description => 'ZIM dumps' }

    include ::dumps::zim
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
