class mediawiki {
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::sync
    include ::mediawiki::users

    include ::ssh::server

    if ubuntu_version('>= trusty') {
        include ::mediawiki::hhvm
    } else {
        include ::mediawiki::php
    }

    file { '/etc/cluster':
        content => $::site,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
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
