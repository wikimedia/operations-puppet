# == Class puppetmaster::puppetdb::client
# Configures a puppetmaster to work as a puppetdb client
class puppetmaster::puppetdb::client($host, $port=443) {
    # Only 3.5+ puppetmasters can work with our version of puppetdb
    requires_os('Debian >= jessie')

    require_package('puppetdb-terminus')

    file { '/etc/puppet/puppetdb.conf':
        ensure  => present,
        content => template('puppetmaster/puppetdb.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
