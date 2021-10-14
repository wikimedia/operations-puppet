# https://wikitech.wikimedia.org/wiki/Security/Peek
#
# If you want to use this class again you'll want to add
# some systemd timers that similar to the ones suggested
# at https://gerrit.wikimedia.org/r/c/operations/puppet/+/730867/3
#
class peek (
    String $to_email,
    String $asana_token,
    String $phab_token,
    Stdlib::Unixpath $template_dir='/var/lib/peek/git/templates/',
    )
{

    package { [
        'python3-jinja2',
        'python3-phabricator',
        'python3-asana',
        'python3-requests-oauthlib',
        'python3-unittest2',
        'python3-testtools',
    ]:
        ensure => present,
    }

    group { 'peek':
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

    file { '/var/lib/peek/.profile':
        ensure  => 'present',
        owner   => 'peek',
        group   => 'peek',
        mode    => '0655',
        content => template('peek/profile.erb'),
    }

    file { '/etc/peek':
        ensure => 'directory',
        owner  => 'peek',
        group  => 'peek',
        mode   => '0640',
    }

    file { '/etc/peek/config':
        ensure  => 'directory',
        owner   => 'peek',
        group   => 'peek',
        mode    => '0640',
        require => File['/etc/peek'],
    }

    file { '/etc/peek/config/base.conf':
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/base.conf.erb'),
        require => File['/etc/peek/config'],
    }

    file { '/etc/peek/config/weekly.conf':
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/weekly.conf.erb'),
        require => File['/etc/peek/config'],
    }

    file { '/etc/peek/config/monthly.conf':
        owner   => 'peek',
        group   => 'peek',
        mode    => '0444',
        content => template('peek/monthly.conf.erb'),
        require => File['/etc/peek/config'],
    }

    git::clone { 'wikimedia/security/tooling/peek':
        ensure    => latest,
        directory => '/var/lib/peek/git',
        branch    => 'master',
        owner     => 'peek',
        group     => 'peek',
    }
}
