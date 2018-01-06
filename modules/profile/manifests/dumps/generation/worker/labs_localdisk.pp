# Provide space for writing dumps to local filesystem
#
# filtertags: labs-common
class profile::dumps::generation::worker::labs_localdisk {
    $xmldumpsmount = '/mnt/dumpsdata'

    labs_lvm::volume { 'data-local-disk':
        mountat => $xmldumpsmount,
    }
}
