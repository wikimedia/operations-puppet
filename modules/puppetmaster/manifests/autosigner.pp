# = Class: puppetmaster::autosigner
# Automatically signs new puppet & salt certificate requests
class puppetmaster::autosigner {

    $puppetmaster_service_name = hiera('labs_puppet_master')

    file { '/usr/local/sbin/certcleaner.py':
        ensure  => present,
        content => template('puppetmaster/certcleaner.py.erb'),
        mode    => '0550',
        owner   => 'root',
        group   => 'root'
    }

    cron { 'puppet_certificate_signer':
        command => '/usr/local/sbin/puppetsigner.py > /dev/null 2>&1',
        ensure  => absent,
    }

    cron { 'puppet_salt_certificate_cleaner':
        command => '/usr/local/sbin/cercleaner.py > /dev/null 2>&1',
        require => File['/usr/local/sbin/certcleaner.py'],
        user    => 'root',
    }
}
