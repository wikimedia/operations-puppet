class base::labs inherits base {
    include apt::unattendedupgrades,
        apt::noupgrade

    # Labs instances /var is quite small, provide our own default
    # to keep less records (T71604).
    file { '/etc/default/acct':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/labs-acct.default',
    }

    if $::operatingsystem == 'Debian' {
        # Turn on idmapd by default
        file { '/etc/default/nfs-common':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/labs/nfs-common.default',
        }

        # enable memory cgroups
        augeas { 'grub2':
            incl    => '/etc/default/grub',
            lens    => 'Shellvars_list.lns',
            changes => [
                'set GRUB_CMDLINE_LINUX/value[. = "cgroup_enable=memory"] cgroup_enable=memory',
                'set GRUB_CMDLINE_LINUX/value[. = "swapaccount=1"] swapaccount=1',
            ],
            notify  => Exec['update-grub'],
        }
    }

    file { '/usr/local/sbin/puppetalert.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/base/labs/puppetalert.py',
    }

    if hiera('send_puppet_failure_emails', false) {
        cron { 'send_puppet_failure_emails':
            ensure  => present,
            command => '/usr/local/sbin/puppetalert.py',
            hour    => 8,
            minute  => '15',
            user    => 'root',
        }
    }
}
