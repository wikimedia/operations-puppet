class mediawiki {
    include ::mediawiki::users
    include ::mediawiki::sync
    include ::mediawiki::cgroup
    include ::mediawiki::nutcracker
    include ::mediawiki::packages
    include ::ssh::server

    file { '/etc/cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $::site,
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
