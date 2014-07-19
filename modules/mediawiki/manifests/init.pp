class mediawiki {
    include ::mediawiki::users
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::ssh::server

    $module_path = get_module_path($module_name)
    $data_path   = "${module_path}/data/${::realm}"

    file { '/etc/cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $::site,
    }

    class { '::nutcracker':
        server_list => loadyaml("${data_path}/memcached.yaml"),
    }

    # Increase scheduling priority of SSHD
    file { '/etc/init/ssh.override':
        content => "nice -10\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['ssh'],
    }

    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => 'apache',
        group  => 'wikidev',
        mode   => '0644',
    }
}
