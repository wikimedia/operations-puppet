# installs required packages for a planet-venus server
class planet::packages {

    # the main package
    # prefer to update this manually
    package { 'planet-venus':
        ensure => 'present',
    }

    # feedparser: we added a workaround for bug T47806
    file { '/usr/share/pyshared/planet/vendor/feedparser.py':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0555',
        require => Package['planet-venus'],
    }

}
