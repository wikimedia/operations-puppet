# Class: puppetmaster::config
#
# This class handles the master part of /etc/puppet.conf.
# Do not include directly.
class puppetmaster::config(
    Hash $config,
    Puppetmaster::Server_type $server_type,
){

    concat::fragment { 'master':
        target  => '/etc/puppet/puppet.conf',
        order   => '20',
        content => template('puppetmaster/master.conf.erb'),
    }

    # See https://tickets.puppetlabs.com/browse/PUP-1237
    #
    # As we already have the ACLs defined in apache (see passenger.pp), and masters do not work
    # with the standalone/webrick install, we can safely move ACLs away from here
    file { '/etc/puppet/fileserver.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/fileserver.conf.erb'),
    }
}
