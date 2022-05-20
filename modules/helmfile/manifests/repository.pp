# SPDX-License-Identifier: Apache-2.0
class helmfile::repository(
    String $repository,
    Stdlib::Unixpath $srcdir,
) {
    git::clone { $repository:
        ensure    => 'present',
        directory => $srcdir,
    }

    systemd::timer::job { 'git_pull_charts':
        ensure          => present,
        description     => 'Pull changes on deployment-charts repo',
        command         => "/bin/bash -c 'cd ${srcdir} && /usr/bin/git pull >/dev/null 2>&1'",
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:*:00', # every minute
        },
        logging_enabled => false,
        user            => 'root',
    }

}
