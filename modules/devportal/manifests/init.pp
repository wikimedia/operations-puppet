# https://dev.wikimedia.org/
# T308
class devportal {

    include ::apache

    file { '/srv/org/wikimedia/devportal':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
    }

    apache::site { 'dev.wikimedia.org':
        content => template('devportal/dev.wikimedia.org.erb'),
    }

}
