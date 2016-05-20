# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {
    include ::apache
    include ::apache::mod::ssl
    include ::apache::mod::perl
    include ::apache::mod::rewrite
    include ::apache::mod::headers
    include ::apache::mod::fastcgi

    if os_version('debian >= jessie') {
        $rt_apache_conf = 'requesttracker/rt4.apache.httponly.erb'
    } else {
        $rt_apache_conf = 'requesttracker/rt4.apache.erb'
    }

    apache::site { 'rt.wikimedia.org':
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

