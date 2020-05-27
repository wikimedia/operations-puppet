class peek (
    $to_email,
    $asana_token,
    $phab_token,
    )
{

    include ::peek::cron

    group {'peek':
        ensure => 'present',
        system => true,
    }

    user { 'peek':
        name       => 'peek',
        comment    => 'Security Team PM tooling',
        home       => '/var/lib/peek',
        managehome => true,
        shell      => false,
        system     => true,
    }

    file { '/etc/peek':
        ensure => 'directory',
        owner  => 'peek',
        group  => 'peek',
        mode   => '0640',
    }

    file { '/etc/peek/templates':
        ensure  => 'directory',
        owner   => 'peek',
        group   => 'peek',
        mode    => '0640',
        require => File['/etc/peek'],
    }

    file {'/etc/peek/templates/base.conf':
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/base.conf.erb'),
        require => File['/etc/peek/templates'],
    }

    file {'/etc/peek/templates/weekly.conf':
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/weekly.conf.erb'),
        require => File['/etc/peek/templates'],
    }

    file {'/etc/peek/templates/monthly.conf':
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/monthly.conf.erb'),
        require => File['/etc/peek/templates'],
    }

    git::clone { 'wikimedia/security/tooling/peek':
        directory => '/var/lib/peek/git',
        branch    => 'master',
        owner     => 'peek',
        group     => 'peek',
    }
}
