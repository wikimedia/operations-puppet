# @summary Sync local operations/puppet.git checkout with upstream.
# @param run_every_minutes how often to run the systemd timer
# @param private_only only sync the private repo
# @param prometheus_file location of the prometheus file
# @param base_dir the base_dir of git repos
# @param git_user the user that owns the git repo
class puppetmaster::gitsync (
    Integer          $run_every_minutes = 10,
    Boolean          $private_only      = false,
    Stdlib::Unixpath $prometheus_file   = '/var/lib/prometheus/node.d/puppet-gitsync.prom',
    Stdlib::Unixpath $base_dir          = '/var/lib/git',
    String[1]        $git_user          = 'root',
) {
    ensure_packages([
        'python3-git',
        'python3-prometheus-client',
        'python3-requests',
    ])

    file { '/usr/local/bin/git-sync-upstream':
        ensure => file,
        source => 'puppet:///modules/puppetmaster/git-sync-upstream.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $private_arg = $private_only.bool2str('--private-only', '')
    $command = @("COMMAND"/L)
        /usr/local/bin/git-sync-upstream --prometheus-file ${prometheus_file} \
        --base-dir ${base_dir} \
        ${private_arg}
        |- COMMAND

    systemd::timer::job { 'puppet-git-sync-upstream':
        ensure      => 'present',
        user        => $git_user,
        description => 'Update local Puppet repository copies',
        command     => $command,
        interval    => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => "${run_every_minutes}m",
        },
    }
}
