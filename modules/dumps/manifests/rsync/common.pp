class dumps::rsync::common(
    $user = undef,
    $group = undef,
) {
    ensure_packages('rsync')

    file { '/etc/rsyncd.d':
        ensure => 'directory',
    }
    file { '/etc/rsyncd.d/00-globalopts.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.globalopts.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
    exec { 'update-rsyncd.conf':
        command     => '/bin/cat /etc/rsyncd.d/*.conf > /etc/rsyncd.conf',
        refreshonly => true,
        require     => File['/etc/rsyncd.d'],
    }
    # We do not need to manage the rsync service on clouddumps100[1-2]
    # since it is managed by an rsync::server::module resource. See #T389784
    unless $facts['networking']['fqdn'] =~ /^clouddumps[\d]{4}/ {
        service { 'rsync':
            ensure    => running,
            enable    => true,
            subscribe => [Exec['update-rsyncd.conf']],
        }
    }
}
