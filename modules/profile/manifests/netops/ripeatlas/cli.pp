# Interact with ripe atlas API from command line
class profile::netops::ripeatlas::cli (
    String $http_proxy = lookup('http_proxy'),
) {
    class { 'netops::ripeatlas::cli':
        http_proxy => $http_proxy,
    }
}
