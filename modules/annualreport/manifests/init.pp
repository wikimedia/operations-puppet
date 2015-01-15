# https://annual.wikimedia.org/
# T599
class annualreport {

    include ::apache

    file { '/srv/org/wikimedia/annualreport':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0644';
    }

    apache::site { 'annual.wikimedia.org':
        content => template('annualreport/annual.wikimedia.org.erb'),
    }

}
