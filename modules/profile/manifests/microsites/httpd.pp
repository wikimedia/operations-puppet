# webserver for misc. static sites
class profile::microsites::httpd {

    class {'::httpd':
        modules => ['headers', 'rewrite', 'authnz_ldap'],
    }

    ferm::service { 'microsites_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }
}
