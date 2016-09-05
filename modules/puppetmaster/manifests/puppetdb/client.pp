# == Class puppetmaster::puppetdb::client
# Configures a puppetmaster to work as a puppetdb client
class puppetmaster::puppetdb::client($host, $port=443) {
    # Only 3.5+ puppetmasters can work with our version of puppetdb
    require_os("Debian >= jessie")

    require_package('puppetdb-terminus')
    
    file { '/etc/puppet/puppetdb.conf':
        ensure  => present,
        content => inline_template(
            '[ main ]\nserver = <%= @host %>\nport = <%= @port %>\nsoft_write_failure = true\n'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
