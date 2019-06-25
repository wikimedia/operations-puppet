# == Define cdh::exec
#
# In order to make puppet execs work with a Kerberized
# cluster we found out that the easiest solution is to
# execute a wrapper that just runs kinit before executing any
# command that needs authentication. The script is not contained
# in this module but it is supposed to be present at some
# (configurable) known fs path.
#
define cdh::exec(
    $command,
    $user,
    $logoutput = undef,
    $timeout = undef,
    $unless = undef,
    $creates = undef,
    $refreshonly = undef,
    $path = undef,
    $wrapper_path = '/usr/local/bin/kerberos-puppet-wrapper',
    $use_kerberos = false,
) {
    if $use_kerberos {
        if !defined(File[$wrapper_path]) {
            fail('kerberos-puppet-wrapper is not defined in the catalog.')
        }
        $wrapper = "${wrapper_path} ${user} "
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
