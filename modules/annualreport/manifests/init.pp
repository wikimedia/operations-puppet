# sets up the WMF annual report site - https://annual.wikimedia.org/
# T599
class annualreport {

    include ::apache
    include ::apache::mod::headers

    file { '/srv/org/wikimedia/annualreport':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    apache::site { 'annual.wikimedia.org':
        source => 'puppet:///modules/annualreport/annual.wikimedia.org',
    }

    git::clone { 'wikimedia/annualreport':
        ensure    => 'present',
        directory => '/srv/org/wikimedia/annualreport',
        branch    => 'master',
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/org/wikimedia/annualreport'],
    }
}
