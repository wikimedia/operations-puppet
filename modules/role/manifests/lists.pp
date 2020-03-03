# sets up a mailing list server
class role::lists {

    system::role { 'lists': description => 'Mailing list server', }

    include profile::standard
    include profile::backup::host
    include profile::base::firewall

    include profile::lists
    include profile::locales::extended
    $cgi = os_version('debian < stretch') ? {
        true    => 'cgi',
        default => 'cgid',
    }
    class { 'httpd':
        modules => [
            'ssl',
            $cgi,
            'headers',
            'rewrite',
            'alias',
            'setenvif',
            'auth_digest',
            ],
    }

}
