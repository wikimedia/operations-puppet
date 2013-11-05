# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns(
    $fqdn = $::fqdn,
    $nameservers = [ $::fqdn ],
    $ipaddress = undef,
    $ipaddress6 = undef,
    $gitrepo = undef,
    $monitoring = true,
) {
    require authdns::account
    require authdns::scripts
    require geoip::data::puppet

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
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }
    # to be replaced with config + include statement, post-1.9.0
    file { '/etc/gdnsd/config-head':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/config-head.erb"),
        require => File['/etc/gdnsd'],
    }
    file { '/etc/gdnsd/zones':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
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
                File['/etc/gdnsd/config-head'],
                Git::Clone['/srv/authdns/git'],
            ],
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before      => Package['gdnsd'],
    }

    if $monitoring {
        include authdns::monitoring
    }

    # export the SSH host key for service hostname/IP keys too
    if $fqdn != $::fqdn {
        @@sshkey { $fqdn:
            ensure => 'present',
            type   => 'ssh-rsa',
            key    => $::sshrsakey,
        }
    }
    if $ipaddress {
        @@sshkey { $ipaddress:
            ensure => 'present',
            type   => 'ssh-rsa',
            key    => $::sshrsakey,
        }
    }
    if $ipaddress6 {
        @@sshkey { $ipaddress6:
            ensure => 'present',
            type   => 'ssh-rsa',
            key    => $::sshrsakey,
        }
    }
}
