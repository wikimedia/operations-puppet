# = Define: labstore::fileserver::replicate
# Simple systemd based unit to replicate a given volume
# from current host to destination
define labstore::fileserver::replicate(
    $src_path,
    $dest_path,
    $dest_host,
) {
    base::service_unit { "replicate-${title}":
        template_name   => 'replicate',
        ensure          => present,
        systemd         => true,
        declare_service => false,
    }
}
