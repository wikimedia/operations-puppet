class role::mediawiki::appserver::api {
    system::role { 'role::mediawiki::appserver::api': }

    include ::role::mediawiki::webserver

    # Using fastcgi we need more local ports
    sysctl::parameters { 'raise_port_range':
        values   => { 'net.ipv4.local_port_range' => '22500 65535' },
        priority => 90,
    }
}
