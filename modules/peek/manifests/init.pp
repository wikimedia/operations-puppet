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

    $templates_dir = '/etc/peek/templates'
    file { $templates_dir:
        ensure  => 'directory',
        owner   => 'peek',
        group   => 'peek',
        mode    => '0640',
        require => File['/etc/peek'],
    }

    file {"${templates_dir}/base.conf":
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/base.conf.erb'),
        require => $templates_dir,
    }

    file {"${templates_dir}/weekly.conf":
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/weekly.conf.erb'),
        require => $templates_dir,
    }

    file {"${templates_dir}/monthly.conf":
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/monthly.conf.erb'),
        require => $templates_dir,
    }

    git::clone { 'peek':
        directory => '/var/lib/peek/',
        branch    => 'master',
        owner     => 'peek',
        group     => 'peek',
    }
}
