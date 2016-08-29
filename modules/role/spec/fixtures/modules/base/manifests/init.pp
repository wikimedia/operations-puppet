class base {}

class base::firewall {}

class base::no_nfs_client {}

class base::puppet::common {}

define base::puppet::config(
    $ensure='present',
    $prio=10,
    $content=undef,
    $source=undef,
) {
}

define base::service_unit(
    $ensure           = present,
    $systemd          = false,
    $systemd_override = false,
    $upstart          = false,
    $sysvinit         = false,
    $strict           = true,
    $refresh          = true,
    $template_name    = $name,
    $declare_service  = true,
    $service_params   = {},
) {
    # Fullfil dependencies to Service['foo']
    if $declare_service {
        service { $name: }
    }
}
