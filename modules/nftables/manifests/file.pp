# SPDX-License-Identifier: Apache-2.0
define nftables::file (
    String         $content,
    Wmflib::Ensure $ensure  = present,
    Integer[0,999] $order   = 0,
) {
    @file { sprintf('/etc/nftables/%03d_%s_puppet.nft', $order, $title):
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
