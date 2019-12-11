# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns(
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers,
    $gitrepo = undef,
) {
    require ::authdns::account
    require ::authdns::scripts

    # The package would create this as well if missing, but this allows
    # puppetization to create directories and files owned by these before the
    # package is even installed...
    group { 'gdnsd':
        ensure => present,
        system => true,
    }
    user { 'gdnsd':
        ensure     => present,
        gid        => 'gdnsd',
        shell      => '/bin/false',
        comment    => '',
        home       => '/var/run/gdnsd',
        managehome => false,
        system     => true,
        require    => Group['gdnsd'],
    }

    package { 'gdnsd':
        ensure => installed,
    }

    # Ensure that 'restarts' are converted to seamless reloads; it never needs
    # a true restart under any remotely normal conditions.
    service { 'gdnsd':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        restart    => 'service gdnsd reload',
        require    => Package['gdnsd'],
    }

    $workingdir = '/srv/authdns/git' # export to template

    file { '/etc/wikimedia-authdns.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template("${module_name}/wikimedia-authdns.conf.erb"),
        before  => Exec['authdns-local-update'],
    }

    # do the initial clone via puppet
    git::clone { $workingdir:
        directory => $workingdir,
        origin    => $gitrepo,
        branch    => 'master',
        owner     => 'authdns',
        group     => 'authdns',
        notify    => Exec['authdns-local-update'],
    }

    exec { 'authdns-local-update':
        command     => '/usr/local/sbin/authdns-local-update --skip-review --initial',
        user        => root,
        refreshonly => true,
        timeout     => 60,
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before      => Package['gdnsd'],
    }
}
