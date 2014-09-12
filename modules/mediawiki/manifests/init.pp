class mediawiki {
    include ::mediawiki::cgroup
    include ::mediawiki::packages
    include ::mediawiki::scap
    include ::mediawiki::users
    include ::mediawiki::syslog
    include ::mediawiki::php

    include ::ssh::server

    if ubuntu_version('>= trusty') {
        include ::mediawiki::hhvm
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
