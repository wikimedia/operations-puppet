# sets up a mailing list server
class role::lists {

    system::role { 'lists': description => 'Mailing list server', }

    include profile::standard
    include profile::backup::host
    include profile::base::firewall

    include profile::lists
    include profile::lists::jobs
    include profile::locales::extended
    class { 'httpd':
        modules => [
            'ssl',
            'cgid',
            'headers',
            'rewrite',
            'alias',
            'setenvif',
            'auth_digest',
            'proxy_http',
            'proxy_uwsgi'
            ],
    }

}
