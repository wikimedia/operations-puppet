# SPDX-License-Identifier: Apache-2.0
define nftables::file (
    String         $content,
    Wmflib::Ensure $ensure  = present,
    Integer        $order   = 0,
) {
    @file { "/etc/nftables/${order}_${title}_puppet.nft":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        require => File['/etc/nftables/'],
        notify  => Systemd::Service['nftables'],
        tag     => 'nft',
    }
}
