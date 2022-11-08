# SPDX-License-Identifier: Apache-2.0
class profile::puppet_compiler::clean_reports {
    $output_dir = '/srv/jenkins/puppet-compiler/output'
    systemd::timer::job {'delete-old-output-files':
        ensure      => 'present',
        description => 'Clean up old PCC reports',
        command     => "/usr/bin/find ${output_dir} -ctime +31 -delete",
        user        => 'root',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
    }
    $large_cleanup_cmd = @("CLEANUP_CMD"/L$)
    /usr/bin/find ${output_dir} -mindepth 1 -maxdepth 1 -type d -ctime +7 -exec du -ks {} + | \
    awk '\$1 >= 1000000 {print \$2}' | \
    xargs rm -rf \
    | CLEANUP_CMD
    systemd::timer::job {'delete-old-output-large-reports':
        ensure      => 'present',
        description => 'Clean up PCC reports older than 7 days and bigger than 1G',
        command     => $large_cleanup_cmd,
        user        => 'root',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
    }
}
