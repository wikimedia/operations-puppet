# Class: puppetmaster::labs
#
# This class handles the Wikimedia Labs specific bits of a Puppetmaster
class puppetmaster::labs {
    package { 'libldap-ruby1.8': ensure => latest; }
    # Use a specific revision for the checkout, to ensure we are using
    # a known and approved version of this script.
    file {
        '/usr/local/sbin/puppetsigner.py':
            ensure => link,
            target => '/usr/local/lib/instance-management/puppetsigner.py',
    }

    cron {
        'puppet_certificate_signer':
            command => '/usr/local/sbin/puppetsigner.py --scriptuser > /dev/null 2>&1',
            require => File['/usr/local/sbin/puppetsigner.py'],
            user    => 'root',
    }
}
