# == Class authdns
# Base authdns setup shared by authdns::ns and authdns::lint
#
# $nameservers - Array of FQDN of nameservers participating in
#     "authdns-update" scheme for syncing zone data.  If left un-set, will
#     default to only the local machine's FQDN, creating what is effectively
#     an isolated test server.
# $gitrepo - If defined, this is the repo to pull DNS zone data from, and
#     this code assumes setup of a live gdnsd server and ensures config is
#     templated and git data is pulled into place before the package is
#     installed to avoid potentially issuing REFUSED for unknown zones, etc.
#     If undefined (the default), the gdnsd OS-level service is
#     disabled/stopped, and no data syncing for zone data is set up at all.
# $config_dir - default "/etc/gdnsd" - place where config files deployed.
#
class authdns(
    $nameservers = [ $::fqdn ],
    $gitrepo = undef,
    $config_dir='/etc/gdnsd',
) {
    require ::authdns::scripts

    if $gitrepo {
        require ::geoip::data::puppet
        $svc_ensure = 'running'
        $svc_enable = true
    }
    else {
        include ::geoip
        $svc_ensure = 'stopped'
        $svc_enable = false
    }

    package { 'gdnsd':
        ensure => installed,
    }

    service { 'gdnsd':
        ensure     => $svc_ensure,
        enable     => $svc_enable,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['gdnsd'],
    }

    file { $config_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${config_dir}/config":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/config.erb"),
        require => File[$config_dir],
        notify  => Service['gdnsd'],
    }

    file { "${config_dir}/discovery-geo-resources":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-geo-resources.erb"),
        require => File[$config_dir],
        notify  => Service['gdnsd'],
    }

    file { "${config_dir}/discovery-metafo-resources":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-metafo-resources.erb"),
        require => File[$config_dir],
        notify  => Service['gdnsd'],
    }

    file { "${config_dir}/discovery-states":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-states.erb"),
        require => File[$config_dir],
        notify  => Service['gdnsd'],
    }

    file { "${config_dir}/discovery-map":
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///modules/${module_name}/discovery-map",
        require => File[$config_dir],
        notify  => Service['gdnsd'],
    }

    file { "${config_dir}/zones":
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if $gitrepo {
        require ::authdns::account

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

        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        exec { 'authdns-local-update':
            command     => '/usr/local/sbin/authdns-local-update --skip-review',
            user        => root,
            refreshonly => true,
            timeout     => 60,
            before      => Package['gdnsd'],
            require     => [
                File['/etc/wikimedia-authdns.conf'],
                File["${config_dir}/config"],
                File["${config_dir}/discovery-geo-resources"],
                File["${config_dir}/discovery-metafo-resources"],
                File["${config_dir}/discovery-states"],
                File["${config_dir}/discovery-map"],
                Git::Clone['/srv/authdns/git'],
            ],
        }
    }
}
