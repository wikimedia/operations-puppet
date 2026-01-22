# SPDX-License-Identifier: Apache-2.0
# @summary Fragment of the dumps distribution rsync config file
define dumps::rsync::fragment (
    String[1] $content,
) {
    concat::fragment { "rsyncd-20-${title}":
        target  => '/etc/rsyncd.conf',
        content => $content,
        order   => "20-${title}",
        notify  => Service['rsync'],
    }
}
