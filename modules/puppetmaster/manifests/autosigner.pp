# = Class: puppetmaster::autosigner
#
# Automatically signs new puppet & salt certificate requests
class puppetmaster::autosigner {
    file { '/usr/local/sbin/puppetsigner.py':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/puppetsigner.py',
        mode   => '0550',
        owner  => 'root',
        group  => 'root'
    }

    cron { 'puppet_certificate_signer':
        command => '/usr/local/sbin/puppetsigner.py > /dev/null 2>&1',
        require => File['/usr/local/sbin/puppetsigner.py'],
        user    => 'root',
    }
}
