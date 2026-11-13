class monitoring (
    String[1]            $contact_group         = 'admin',
    String[1]            $cluster               = 'misc',
    String[1]            $nagios_group          = 'misc',
    Boolean              $notifications_enabled = true,
    Boolean              $do_paging             = true,
    Boolean              $host_critical         = false,
    Hash                 $services              = {},
) {
    $services.each |$service, $config| {
        monitoring::service { $service:
            * => $config,
        }
    }
}
