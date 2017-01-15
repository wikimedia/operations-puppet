# Class: puppetmaster::labsrootpass
#
# Set up a script to generate root passwords for puppet clients
#
#  Used in labs instance roles like this:
#
#    user { 'root':
#        password => generate('/usr/local/sbin/make-labs-root-password', $::labsproject)
#    }
#

class puppetmaster::labsrootpass {

    require_package('pwgen')
    require_package('whois')

    file { '/usr/local/sbin/make-labs-root-password':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/make-labs-root-password',
    }

    file { '/var/local/labs-root-passwords':
        ensure => 'directory',
        owner  => 'puppet',
        mode   => '0700',
    }
}
