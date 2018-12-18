# This establishes the basics for every SGE node

class profile::toolforge::grid::base (
    $external_hostname = hiera('profile::toolforge::external_hostname', undef),
    $external_ip = hiera('profile::toolforge::external_ip', undef),
    $active_proxy = hiera('profile::toolforge::active_proxy_host'),
    $etcdir = hiera('profile::toolforge::etcdir'),
    $project_path = lookup('profile::toolforge::grid::base::project_path'),
    $sge_root = lookup('profile::toolforge::grid::base::sge_root'),
    $sysdir = lookup('profile::toolforge::grid::base::sysdir'),
    $geconf = lookup('profile::toolforge::grid::base::geconf'),
    $collectors = lookup('profile::toolforge::grid::base::collectors'),
) {

    class { '::labs_lvm': }

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

    file { "${store}/hostkey-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::fqdn},${::hostname},${::ipaddress} ssh-rsa ${::sshrsakey}\n${::fqdn},${::hostname},${::ipaddress} ecdsa-sha2-nistp256 ${::sshecdsakey}\n",
        require => File[$store],
    }

    if $::labsproject == 'tools' {
        # The following conflicts with the ssh-known-hosts stuff with puppetdb
        # TODO: Remove when adding puppetdb to tools
        exec { 'make_known_hosts':
            command => "/bin/cat ${store}/hostkey-* >/etc/ssh/ssh_known_hosts~",
            onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find ${store} -maxdepth 1 \\( -type d -or -type f -name hostkey-\\* \\) -newer /etc/ssh/ssh_known_hosts~)\" -o ! -s /etc/ssh/ssh_known_hosts~",
            require => File[$store],
        }

        file { '/etc/ssh/ssh_known_hosts':
            ensure  => file,
            source  => '/etc/ssh/ssh_known_hosts~',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Exec['make_known_hosts'],
        }
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

    diamond::collector::localcrontab { 'localcrontabcollector': }
}
