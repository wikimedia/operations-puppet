# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns(
    $nameservers = [ $::fqdn ],
    $gitrepo = undef,
    $monitoring = true,
    $lvs_services,
    $discovery_services,
) {
    require ::authdns::account
    require ::authdns::scripts
    require ::geoip::data::puppet

    package { 'gdnsd':
        ensure => installed,
    }

    service { 'gdnsd':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        require    => Package['gdnsd'],
    }

    # the package creates this, but we want to set up the config before we
    # install the package, so that the daemon starts up with a well-known
    # config that leaves no window where it'd refuse to answer properly
    file { '/etc/gdnsd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/gdnsd/config':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/config.erb"),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
    }
    file { '/etc/gdnsd/zones':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $workingdir = '/srv/authdns/git' # export to template

    file { '/etc/wikimedia-authdns.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template("${module_name}/wikimedia-authdns.conf.erb"),
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
        command     => '/usr/local/sbin/authdns-local-update --skip-review',
        user        => root,
        refreshonly => true,
        timeout     => 60,
        require     => [
                File['/etc/wikimedia-authdns.conf'],
                File['/etc/gdnsd/config'],
                Git::Clone['/srv/authdns/git'],
            ],
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before      => Package['gdnsd'],
    }

    if $monitoring {
        include ::authdns::monitoring
    }

    # Discovery Magic

    file { '/etc/gdnsd/discovery-geo-resources':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-geo-resources.erb"),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
    }

    file { '/etc/gdnsd/discovery-metafo-resources':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-metafo-resources.erb"),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
    }

    file { '/etc/gdnsd/discovery-states':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-states.erb"),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
    }

    create_resources(::authdns::discovery_statefile, $discovery_services, { lvs_services => $lvs_services })
}
