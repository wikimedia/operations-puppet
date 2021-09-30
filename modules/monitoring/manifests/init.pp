class monitoring (
    String[1]            $contact_group         = 'admin',
    String[1]            $mgmt_contact_group    = 'admin',
    String[1]            $cluster               = 'misc',
    String[1]            $nagios_group          = 'misc',
    Boolean              $notifications_enabled = true,
    Boolean              $do_paging             = true,
    Hash                 $hosts                 = {},
    Hash                 $services              = {},
    Hash[String, String] $mgmt_parents          = {},
) {
    $hosts.each |$host, $config| {
        monitoring::host { $host:
            * => $config,
        }
    }
    $services.each |$service, $config| {
        monitoring::service { $service:
            * => $config,
        }
    }
}
