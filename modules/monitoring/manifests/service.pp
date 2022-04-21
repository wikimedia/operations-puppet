define monitoring::service(
    String                            $check_command,
    String                            $notes_url,
    Wmflib::Ensure                    $ensure                = present,
    Optional[String]                  $description           = undef,
    Integer                           $retries               = 3,
    Boolean                           $critical              = false,
    Boolean                           $passive               = false,
    Integer                           $freshness             = 36000, # sec
    Integer                           $check_interval        = 1, # min
    Integer                           $retry_interval        = 1, # min
    Stdlib::Unixpath                  $config_dir            = '/etc/nagios',
    Variant[Stdlib::Host,String]      $host                  = $facts['hostname'],
    Optional[String]                  $contact_group         = undef,
    Optional[String]                  $group                 = undef,
    Optional[Boolean]                 $notifications_enabled = undef,
    Optional[Variant[Boolean,String]] $event_handler         = undef,
){

    include monitoring
    $cluster_name           = $monitoring::cluster
    $do_paging              = $monitoring::do_paging
    # cast undef to an empty string
    # lint:ignore:only_variable_string
    $description_safe       = "${description}".regsubst('[`~!$%^&*"|\'<>?,()=]', '-', 'G')
    # lint:endignore
    $_notifications_enabled = pick($notifications_enabled, $monitoring::notifications_enabled)
    $servicegroups          = pick($group, $monitoring::nagios_group)
    $_contact_group         = pick($contact_group, $monitoring::contact_group)

    if $check_command =~ /\\n/ {
        fail("Parameter check_command cannot contain newlines: ${check_command}")
    }

    $notification_interval = $critical ? {
        true    => 240,
        default => 0,
    }

    # If a service is set to critical and
    # paging is not disabled for this machine in hiera,
    # then use the "sms" contact group which creates pages.

    case $critical {
        true: {
            case $do_paging {
                true:    {
                  $real_contact_groups = "${_contact_group},sms,admins"
                  $real_description = "${description_safe} #page"
                }
                default: {
                  $real_contact_groups = "${_contact_group},admins"
                  $real_description = $description_safe
                }
            }
        }
        default: {
          $real_contact_groups = $_contact_group
          $real_description = $description_safe
        }
    }

    $check_volatile = $passive.bool2num
    $check_fresh = $passive.bool2num
    $is_active = (!$passive).bool2num

    $is_fresh = $passive ? {
        true    => $freshness,
        default => undef,
    }

    # the nagios service instance
    $service = {
        "${::hostname} ${title}" => {
            ensure                 => $ensure,
            host_name              => $host,
            servicegroups          => $servicegroups,
            service_description    => $real_description,
            check_command          => $check_command,
            max_check_attempts     => $retries,
            check_interval         => $check_interval,
            retry_interval         => $retry_interval,
            check_period           => '24x7',
            notification_interval  => $notification_interval,
            notification_period    => '24x7',
            notification_options   => 'c,r,f',
            notifications_enabled  => $_notifications_enabled.bool2str('1', '0'),
            contact_groups         => $real_contact_groups,
            passive_checks_enabled => 1,
            active_checks_enabled  => $is_active,
            is_volatile            => $check_volatile,
            check_freshness        => $check_fresh,
            freshness_threshold    => $is_fresh,
            event_handler          => $event_handler,
            notes_url              => $notes_url,
        },
    }
    # This is a hack. We detect if we are running on the scope of an icinga
    # host and avoid exporting the resource if yes
    if defined(Class['icinga']) {
        create_resources(nagios_service, $service)
    } else {
        create_resources('monitoring::exported_nagios_service', $service)
    }
}
