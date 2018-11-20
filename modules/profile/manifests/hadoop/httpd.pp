# Class: profile::hadoop::httpd
#
# Sets up a webserver for Hadoop UIs
class profile::hadoop::httpd {

    class { '::httpd':
        modules => ['proxy_http',
                    'proxy',
                    'proxy_html',
                    'headers',
                    'xml2end',
                    'auth_basic',
                    'authnz_ldap']
    }

    ferm::service { 'hadoop-ui-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
