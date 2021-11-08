class openstack::monitor::networktests (
    String[1]    $region,
    Stdlib::Fqdn $sshbastion,
    Hash         $envvars,
) {
    $basedir = '/etc/networktests'
    file { $basedir:
        ensure => directory,
    }

    $sshkeyfile = "${basedir}/sshkeyfile"
    file { $sshkeyfile:
        ensure    => present,
        mode      => '0600',
        show_diff => false,
        content   => secret("openstack/monitor/networktests/${region}/sshkeyfile"),
    }

    # this user has been created by hand in LDAP, so it exists in every VM
    # it was also created in codfw1dev. Same user with different ssh key
    $sshuser = 'srv-networktests'

    $ssh_identity = "-i ${sshkeyfile} -o User=${sshuser}"
    $ssh_opts = '-o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o NumberOfPasswordPrompts=0'
    $ssh_proxy = "-o Proxycommand=\"ssh -o StrictHostKeyChecking=no -i ${sshkeyfile} -W %h:%p ${sshuser}@${sshbastion}\""
    $ssh = "/usr/bin/ssh ${ssh_identity} ${ssh_opts} ${ssh_proxy}"

    file { "${basedir}/networktests.yaml":
        ensure  => present,
        content => template('openstack/monitor/networktests.yaml.erb'),
    }

    file { '/usr/local/bin/cmd-checklist-runner':
        ensure => present,
        source => 'puppet:///modules/openstack/monitor/cmd-checklist-runner.py',
    }

    # TODO: deploy systemd timer to trigger the runner script

    # TODO: deploy icinga collector, and/or an emailer with the results
}
