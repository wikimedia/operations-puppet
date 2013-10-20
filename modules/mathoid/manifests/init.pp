class mathoid {
    package { 'npm':
        ensure => present,
        before => Exec['install mathoid'],
    }

    package { 'phantomjs':
        ensure => present,
        before => Exec['install mathoid'],
    }

    git::clone { 'Math':
        directory => '/usr/local/bin/Math',
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/extensions/Math',
       # creates   => '/usr/local/bin/Math/mathoid/start.sh',
    }

    file { '/etc/init/wmf-mathoid.conf':
            owner => root,
            group => root,
            mode => 0444,
            source => 'puppet:///files/upstart/wmf-mathoid.conf',
    }

    exec { 'install mathoid':
       command => '/usr/bin/npm install',
        cwd     => '/usr/local/bin/Math/mathoid',
        creates => '/usr/local/bin/Math/mathoid/node_modules',
        require => [ Package['npm', 'phantomjs'], Git::Clone['Math'] ],
        user    => root,
        before => Service['wmf-mathoid'],
    }

   upstart_job { 'wmf-mathoid': install => true }

    service { 'wmf-mathoid':
        require => [
            #File['/usr/local/bin/Math/mathoid/start.sh'], #depends on https://gerrit.wikimedia.org/r/#/c/90731/
            Upstart_job['wmf-mathoid'],
            #Systemuser['mathoid'], #do we need that?
            Exec['install mathoid'],
        ],
        provider => upstart,
        ensure => running,
    }
}