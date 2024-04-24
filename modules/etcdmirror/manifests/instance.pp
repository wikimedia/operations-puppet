# SPDX-License-Identifier: Apache-2.0
# == define etcdmirror::instance
#
# Sets up a replication mirroring from a prefix on one etcd server to a prefix
# on another.
#
# === Parameters
#
# [*src*] URI for the etcd server we're replicating from
#
# [*src_path*] Source path to replicate from (relative to /v2/keys)
#
# [*dst*] URI for the etcd server we're replicating todo
#
# [*dst_path*] Destination path to replicate to (relative to /v2/keys)
#
# [*enable*] If service is to be enabled or not
#
# [*src_ignore_keys_regex*] Optional fully anchored regex for keys that should
#                           not be replicated.
#
define etcdmirror::instance(
    Stdlib::HTTPUrl  $src,
    Stdlib::Unixpath $src_path,
    Stdlib::HTTPUrl  $dst,
    Stdlib::Unixpath $dst_path,
    Boolean          $enable,
    Optional[String] $src_ignore_keys_regex = undef
) {
    ensure_packages('etcd-mirror')

    # safe version of the title
    $prefix = regsubst("etcdmirror${title}", '\W', '-', 'G')

    $service_status = $enable ? {
        true    => 'running',
        default => 'stopped',
    }

    $service_params = {
        ensure => $service_status,
        enable => $enable,
    }

    $src_ignore_keys_regex_flag = $src_ignore_keys_regex ? {
        undef   => '',
        default => "--src-ignore-keys-regex '${src_ignore_keys_regex}'"
    }

    systemd::service { $prefix:
        ensure         => present,
        content        => template('etcdmirror/initscripts/etcd-mirror.systemd.erb'),
        restart        => false,
        service_params => $service_params,
    }

    file { "/usr/local/sbin/reload-${prefix}":
        ensure  => present,
        content => inline_template("#!/bin/bash\n/usr/bin/etcd-mirror --strip --reload --src-prefix ${src_path} --dst-prefix ${dst_path} ${src_ignore_keys_regex_flag} ${src} ${dst}"),
        mode    => '0544',
        owner   => 'root',
        group   => 'root',
    }

    systemd::syslog { $prefix:
        ensure       => present,
        owner        => 'root',
        group        => 'root',
        log_filename => 'syslog.log',
    }
}
