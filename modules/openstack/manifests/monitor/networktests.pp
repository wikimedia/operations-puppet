class openstack::monitor::networktests (
    String[1]    $region,
    Stdlib::Fqdn $sshbastion,
    Hash         $envvars,
    Boolean      $timer_active,
) {
    $usr = 'srv-networktests'

    systemd::sysuser { $usr:
        home => "/var/lib/${usr}",
    }

    $basedir = '/etc/networktests'
    file { $basedir:
        ensure => directory,
    }

    $sshkeyfile = "${basedir}/sshkeyfile"
    file { $sshkeyfile:
        ensure    => present,
        mode      => '0600',
        owner     => $usr,
        group     => $usr,
        show_diff => false,
        content   => secret("openstack/monitor/networktests/${region}/sshkeyfile"),
    }

    # this user has been created by hand in LDAP, so it exists in every VM
    # it was also created in codfw1dev. Same user with different ssh key
    $sshuser = 'srv-networktests'

    $ssh_hostkey = '-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR'
    $ssh_identity = "-i ${sshkeyfile} -o User=${sshuser}"
    $ssh_opts = "-q -o ConnectTimeout=5 -o NumberOfPasswordPrompts=0 ${ssh_hostkey}"
    $ssh_proxy = "-o Proxycommand=\"ssh ${ssh_hostkey} -i ${sshkeyfile} -W %h:%p ${sshuser}@${sshbastion}\""
    $ssh = "/usr/bin/ssh ${ssh_identity} ${ssh_opts} ${ssh_proxy}"

    $config = "${basedir}/networktests.yaml"

    file { "${basedir}/networktests.yaml":
        ensure  => present,
        content => template('openstack/monitor/networktests.yaml.erb'),
    }

    $timer_ensure = $timer_active ? {
        true    => 'present',
        default => 'absent',
    }

    systemd::timer::job { 'cloud-vps-networktest':
        ensure              => $timer_ensure,
        description         => 'Run the Cloud VPS network tests',
        command             => "/usr/local/bin/cmd-checklist-runner --config ${config} --exit-code-fail",
        user                => $usr,
        interval            => {
            'start'    => 'OnCalendar',
            'interval' => '*:0/15:00', # every 15 minutes
        },
        max_runtime_seconds => 600, # kill if running after 10 mins
        require             => Class['cmd_checklist_runner'],
    }

    # TODO: deploy some kind of emailer with the results
}
