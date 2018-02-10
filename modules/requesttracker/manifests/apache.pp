# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {

    if os_version('debian >= jessie') {
        $rt_apache_conf = 'requesttracker/rt4.apache.httponly.erb'
    } else {
        $rt_apache_conf = 'requesttracker/rt4.apache.erb'
    }

    httpd::site { 'rt.wikimedia.org':
        content => template($rt_apache_conf),
    }

    # use this to have a NameVirtualHost *:443
    # avoid [warn] _default_ VirtualHost overlap
    file { '/etc/apache2/ports.conf':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/requesttracker/ports.conf.ssl',
    }
}

