class toollabs::maintain_kubeusers(
    $k8s_master,
) {

    # Not using require_package because of dependency cycle, see
    # https://gerrit.wikimedia.org/r/#/c/430539/
    package { 'python3-ldap3':
        ensure => present,
    }

    require_package('python3-yaml')

    file { '/usr/local/bin/maintain-kubeusers':
        source => 'puppet:///modules/toollabs/maintain-kubeusers.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::service { 'maintain-kubeusers':
        ensure  => 'absent',
        content => systemd_template('maintain-kubeusers'),
    }

    $timer_command = "/usr/local/bin/maintain-kubeusers \
                        --once \
                        --infrastructure-users \
                        --/etc/kubernetes/infrastructure-users \
                        --project ${::labsproject} \
                        https://${k8s_master}:6443 \
                        /etc/kubernetes/tokenauth \
                        /etc/kubernetes/abac"

    systemd::timer::job { 'maintain-kubeusers-timer':
        ensure                    => 'present',
        description               => 'Automate the process of generating users',
        command                   => $timer_command,
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00/1:00', # Every 1 minute
        },
        max_runtime_seconds       => 300,  # kill if running after 5m
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => 'root',
    }
}
