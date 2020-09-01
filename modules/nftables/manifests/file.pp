define nftables::file (
    String         $content,
    Wmflib::Ensure $ensure  = present,
    Integer        $order   = 0,
) {
    require ::nftables

    @file { "/etc/nftables/${order}_${title}_puppet.nft":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        require => Class['nftables'],
        notify  => Systemd::Service['nftables'],
        tag     => 'nft',
    }
}
