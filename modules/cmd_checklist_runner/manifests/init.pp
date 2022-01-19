class cmd_checklist_runner (
) {
    $runner = 'cmd-checklist-runner'
    $cmd = "/usr/local/bin/${runner}"

    file { $cmd:
        ensure => present,
        mode   => '0755',
        source => "puppet:///modules/cmd_checklist_runner/${runner}.py",
    }
}
