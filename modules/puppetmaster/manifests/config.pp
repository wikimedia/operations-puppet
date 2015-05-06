# Class: puppetmaster::config
#
# This class handles the master part of /etc/puppet.conf.
# Do not include directly.
class puppetmaster::config {
    include base::puppet

    file { '/etc/puppet/puppet.conf.d/20-master.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/20-master.conf.erb'),
        require => File['/etc/puppet/puppet.conf.d'],
        notify  => Exec['compile puppet.conf']
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
