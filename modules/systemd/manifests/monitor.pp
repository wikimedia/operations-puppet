# @summary check if a systemd unit is active or not
# @param notes_url the url to the wiki tech page used to debug a failed unit
# @param ensure
# @param check_interval how often, in seconds, to check the unit
# @param retries how many time to retry the check before going critical
# @param contact_group the monitoring contact group to alert
# @param critical if true, this will be a paging alert
define systemd::monitor (
    Stdlib::HTTPUrl $notes_url,
    Wmflib::Ensure  $ensure         = 'present',
    Integer[1]      $check_interval = 10,
    Integer[1]      $retries        = 2,
    String          $contact_group  = 'admin',
    Boolean         $critical       = false,
) {
    # T225268 - always provision NRPE plugin script
    ensure_resource('nrpe::plugin', 'check_systemd_unit_status', {
        source => 'puppet:///modules/systemd/check_systemd_unit_status',
    })

    nrpe::monitor_service { "check_${title}_status":
        ensure         => $ensure,
        description    => "Check unit status of ${title}",
        nrpe_command   => "/usr/local/lib/nagios/plugins/check_systemd_unit_status ${title}",
        check_interval => $check_interval,
        retries        => $retries,
        contact_group  => $contact_group,
        notes_url      => $notes_url,
        critical       => $critical,
    }
}
