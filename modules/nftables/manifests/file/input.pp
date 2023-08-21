# SPDX-License-Identifier: Apache-2.0
# Install an input rule for nftables
define nftables::file::input (
    String         $content,
    Wmflib::Ensure $ensure  = present,
    Integer[0,99]  $order   = 0,
) {
    @file { sprintf('/etc/nftables/input/%02d_%s.nft', $order, $title):
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
