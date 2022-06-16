# SPDX-License-Identifier: Apache-2.0
function php::fpm::versioned_port(
    Optional[Stdlib::Port::User] $port,
    Array[Wmflib::Php_version] $versions
) >> Hash[Wmflib::Php_version, Optional[Stdlib::Port::User]] {
    # If a port is defined, use subsequent ones for
    # the various versioned pools.
    # If the port is undefined, the unix socket depends on the
    # pool name.
    return $versions.map |$idx, $version| {
        $pool_port = $port ? {
            undef => $port,
            default => $port + $idx
        }
        $retval = {$version => $pool_port}
    }.reduce({}) |$m, $v| {$m.merge($v)}
}
