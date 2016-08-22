# == define scap::dsh::group
#
# Manages a scap dsh group.
#
# Group entries can be defined either by explicitly providing a
# host list, or defining scap::dsh::group::$title in hiera. Also,
# this can gather all non-inactive nodes from one or more conftool
# pools.
define scap::dsh::group($hosts=undef, $conftool=undef,) {

    $host_list = $hosts ? {
        undef   => hiera("scap::dsh::${title}", []),
        default => $hosts,
    }

    file { "/etc/dsh/group/${title}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('scap/dsh/dsh-group.erb'),
    }

}
