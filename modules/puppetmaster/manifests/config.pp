# Class: puppetmaster::config
#
# This class handles the master part of /etc/puppet.conf.
# Do not include directly.
class puppetmaster::config {
    include base::puppet

    file {
        '/etc/puppet/puppet.conf.d/20-master.conf':
            require => File['/etc/puppet/puppet.conf.d'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('puppetmaster/20-master.conf.erb'),
            notify  => Exec['compile puppet.conf'];
        '/etc/puppet/fileserver.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('puppetmaster/fileserver.conf.erb');
    }
}
