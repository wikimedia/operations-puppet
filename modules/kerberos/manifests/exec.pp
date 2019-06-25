# == Define kerberos::exec
#
# In order to make puppet execs work with a Kerberized
# cluster we found out that the easiest solution is to
# execute a wrapper that just runs kinit before executing any
# command that needs authentication.
#
define kerberos::exec(
    $command,
    $user,
    $logoutput = undef,
    $timeout = undef,
    $unless = undef,
    $creates = undef,
    $refreshonly = undef,
    $path = undef,
    $use_kerberos = false,
) {

    require ::kerberos::wrapper

    if $use_kerberos {
        $wrapper = "${kerberos::wrapper::kerberos_run_command_script} ${user} "
    } else {
        $wrapper = ''
    }

    # 'unless' may contain a hdfs command that needs
    # authentication as well.
    if $unless and $use_kerberos {
        $unless_command = "${wrapper}${unless}"
    } else {
        $unless_command = $unless
    }

    exec { $title:
        command     => "${wrapper}${command}",
        unless      => $unless_command,
        creates     => $creates,
        refreshonly => $refreshonly,
        user        => $user,
        logoutput   => $logoutput,
        timeout     => $timeout,
        path        => $path,
    }
}
