class interface::rps::modparams {
    include initramfs

    if hiera('numa_networking', false) {
       $num_queues = $facts['physicalcorecount'] / $facts['numa']['node_count']
    }
    else {
       $num_queues = $facts['physicalcorecount']
    }

    file { '/etc/modprobe.d/rps.conf':
        content => template("${module_name}/rps.conf.erb"),
        notify  => Exec['update-initramfs']
    }
}
