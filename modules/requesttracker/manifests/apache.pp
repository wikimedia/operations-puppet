# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {
    include ::apache
    include ::apache::mod::php5  # WAT WHY
    include ::apache::mod::ssl
    include ::apache::mod::perl

    apache::site { 'rt.wikimedia.org':
        content => template('requesttracker/rt4.apache.erb'),
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

