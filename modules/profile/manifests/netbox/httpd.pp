# webserver for a standalone netbox server
class profile::netbox::httpd {

    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'ssl',
                    'wsgi',
                    ],
    }

    ferm::service { 'netbox_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
