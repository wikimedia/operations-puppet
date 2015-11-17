# = Class: puppetmaster::certcleaner
# Automatically signs new puppet & salt certificate requests
class puppetmaster::certcleaner {

    $puppetmaster_service_name = hiera('labs_puppet_master', $::fqdn)

    file { '/usr/local/sbin/certcleaner.py':
        ensure  => present,
        content => template('puppetmaster/certcleaner.py.erb'),
        mode    => '0550',
        owner   => 'root',
        group   => 'root'
    }

    cron { 'puppet_certificate_signer':
        ensure  => absent,
        command => '/usr/local/sbin/puppetsigner.py > /dev/null 2>&1',
    }

    cron { 'puppet_salt_certificate_cleaner':
        command => '/usr/local/sbin/certcleaner.py > /dev/null 2>&1',
        require => File['/usr/local/sbin/certcleaner.py'],
        user    => 'root',
    }
}
