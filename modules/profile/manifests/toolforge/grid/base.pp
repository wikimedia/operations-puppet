# This establishes the basics for every SGE node

class profile::toolforge::grid::base (
    Stdlib::Host $active_proxy       = lookup('profile::toolforge::active_proxy_host'),
    Stdlib::Unixpath $etcdir         = lookup('profile::toolforge::etcdir'),
    Stdlib::Unixpath $project_path   = lookup('profile::toolforge::grid::base::project_path'),
    Stdlib::Unixpath $sge_root       = lookup('profile::toolforge::grid::base::sge_root'),
    Stdlib::Unixpath $sysdir         = lookup('profile::toolforge::grid::base::sysdir'),
    Stdlib::Unixpath $geconf         = lookup('profile::toolforge::grid::base::geconf'),
    Stdlib::Unixpath $collectors     = lookup('profile::toolforge::grid::base::collectors'),
    Optional[Stdlib::Host] $external_hostname  = lookup('profile::toolforge::external_hostname', {'default_value' => undef}),
    Optional[Stdlib::IP::Address] $external_ip = lookup('profile::toolforge::external_ip', {'default_value' => undef}),
){
    # Weird use of NFS for config centralization.
    # Nodes drop their config into a directory.
    #  - SSH host keys for HBA
    #  - known_hosts
    $store  = "${sysdir}/store"

    exec {'ensure-grid-is-on-NFS':
        command => '/bin/false',
        unless  => "/usr/bin/timeout -k 5s 60s /usr/bin/test -e ${project_path}/herald",
    }

    file { $sysdir:
        ensure  => directory,
        owner   => 'root',
        group   => "${::labsproject}.admin",
        mode    => '2775',
        require => Exec['ensure-grid-is-on-NFS'],
    }

    file { $geconf:
        ensure  => directory,
        require => File[$sysdir],
    }

    file { $sge_root:
        ensure  => link,
        target  => $geconf,
        force   => true,
        require => File[$geconf],
    }

    file { $collectors:
        ensure  => directory,
        require => File[$geconf],
    }

    file { $store:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File[$sysdir],
    }

    file { [
        "${store}/hostkey-${::fqdn}",
        '/etc/ssh/ssh_known_hosts~'
    ]:
        ensure  => absent,
    }

    File['/var/lib/gridengine'] -> Package <| title == 'gridengine-common' |>

    file { '/shared':
        ensure  => link,
        target  => "${project_path}/.shared",
        require => Exec['ensure-grid-is-on-NFS'],
    }

    # Link to currently active proxy
    file { '/etc/active-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $active_proxy,
    }

    class { 'profile::prometheus::node_local_crontabs': }
}
