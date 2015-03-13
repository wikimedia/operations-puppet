# = Class: puppetmaster::autosigner
#
# Automatically signs new puppet certificate requests
class puppetmaster::autosigner {
    # Use a specific revision for the checkout, to ensure we are using
    # a known and approved version of this script.
    # FIXME: Above commit doesn't seem to reflect reality?
    file { '/usr/local/sbin/puppetsigner.py':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/puppetsigner.py',
        mode   => '0550',
        owner  => 'root',
        group  => 'root'
    }

    cron { 'puppet_certificate_signer':
        command => '/usr/local/sbin/puppetsigner.py --scriptuser > /dev/null 2>&1',
        require => File['/usr/local/sbin/puppetsigner.py'],
        user    => 'root',
    }
}
