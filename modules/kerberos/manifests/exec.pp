# SPDX-License-Identifier: Apache-2.0
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
) {

    require ::kerberos::wrapper

    # To ease testing in cloud/labs, there is a tunable that can be used
    # to skip the wrapper command and avoid the Kerberos authentication.
    if $::kerberos::wrapper::skip_wrapper {
        $wrapper = ''
    } else {
        $wrapper = "${kerberos::wrapper::kerberos_run_command_script} ${user} "
    }

    # 'unless' may contain a hdfs command that needs
    # authentication as well.
    if $unless {
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
