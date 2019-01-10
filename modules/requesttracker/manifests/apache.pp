# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {

    $rt_apache_conf = 'requesttracker/rt4.apache.httponly.erb'

    httpd::site { 'rt.wikimedia.org':
        content => template($rt_apache_conf),
    }

    # avoid [warn] _default_ VirtualHost overlap
    file { '/etc/apache2/ports.conf':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/requesttracker/ports.conf.ssl',
    }
}

