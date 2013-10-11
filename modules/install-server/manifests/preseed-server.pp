#

class install-server::preseed-server {
    file { '/srv/autoinstall':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        path    => '/srv/autoinstall/',
        source  => 'puppet:///files/autoinstall',
        recurse => true,
        links   => manage
    }
}
