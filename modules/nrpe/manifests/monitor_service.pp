# Definition: nrpe::monitor_service
#
# Defines a Nagios check for a remote service over NRPE
#
# Also optionally installs a corresponding NRPE check file
# using nrpe::check
#
# Parameters
#    $ensure
#       Defaults to present
#    $description
#       Service check description
#    $nrpe_command
#       The path to the actual binary/script. A stanza for nrpe daemon will be
#       added with that path and a nagios_service check will be exported to
#       nagios server.
#    $contact_group
#       Defaults to admins, the nagios contact group for the service
#    $retries
#       Defaults to 3. The number of times a service will be retried before
#       notifying
#    $timeout
#       Defaults to 10. The check timeout in seconds (check_nrpe -t option)
#    $critical
#       Defaults to false. If true, this will be a paging alert.
#    $event_handler
#       Default to false. If present execute this registered command on the
#       Nagios server.
#    $migration_task
#       Phab task that tracks the migrations of current check
#    $nrpe2nodexp_parse_perf_data
#       Default to false. It enables nrpe2nodexp to parse performance data.
#       perfdata must be in the format described here:
#       https://nagios-plugins.org/doc/guidelines.html#AEN200
#    $notes_url
#       A required URL used to provide information about the service.
#       Ideally a runbook how to handle alerts on Wikitech. Must not be URL-encoded.
#    $dashboard_link
#       An optional URL to link to grafana or another monitoring dashboard.
#       Must not be URL-encoded.
#
define nrpe::monitor_service(
    Wmflib::Ensure $ensure                                = present,
    $description                                          = undef,
    $nrpe_command                                         = undef,
    $contact_group                                        = lookup('contactgroups', {default_value => 'admins'}),
    $retries                                              = 3,
    $timeout                                              = 10,
    Boolean $critical                                     = false,
    $event_handler                                        = undef,
    $check_interval                                       = 1, # min
    $retry_interval                                       = 1, # min
    $migration_task                                       = 'T321808',
    # needed to manage the icinga->prom/am migration
    Boolean $enable_nrpe2nodexp                           = lookup('enable_nrpe2nodexp', {default_value => false}),  # lint:ignore:wmf_styleguide
    # needed to manage the icinga->prom/am migration
    Boolean $enable_icinga_check                          = true,
    Boolean $nrpe2nodexp_parse_perf_data                  = false,
    Optional[Stdlib::HTTPSUrl] $notes_url                 = undef,
    Optional[Array[Stdlib::HTTPSUrl, 1]] $dashboard_links = undef,
    Optional[String] $sudo_user                           = undef,
) {
    unless $ensure == 'absent' or ($description and $nrpe_command and $notes_url) {
        fail('Description, nrpe_command, and notes_url parameters are mandatory for ensure != absent')
    }

    nrpe::check { "check_${title}":
        ensure    => $ensure,
        command   => $nrpe_command,
        sudo_user => $sudo_user,
        before    => Monitoring::Service[$title],
    }

    $ensure_icinga_check_cond = (($enable_icinga_check) and ($ensure == 'present'))
    $ensure_icinga_check = $ensure_icinga_check_cond ? {
        true  => 'present',
        false => 'absent'
    }

    if $enable_icinga_check {
        $notes_urls = monitoring::build_notes_url($notes_url,
            ($dashboard_links) ? {undef => [], default => $dashboard_links})

        monitoring::service { $title:
            ensure         => $ensure_icinga_check,
            description    => $description,
            check_command  => "nrpe_check!check_${title}!${timeout}",
            contact_group  => $contact_group,
            retries        => $retries,
            critical       => $critical,
            event_handler  => $event_handler,
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            notes_url      => $notes_urls,
        }
    }

    # The `ensure` parameter must be set to a constant value,
    # such as 'present' or 'absent', in a consistent way.
    # If it's bound to the `$ensure` parameter coming from the class,
    # it may result in a duplicate declaration error.
    # https://doc.wikimedia.org/mediawiki-vagrant/puppet_functions_ruby3x/ensure_resource.html
    # It is outside of the $enable_nrpe2nodexp for the same reason.
    if debian::codename::ge('bullseye') {
        ensure_packages(['python3-click', 'python3-box', 'python3-prometheus-client'])
    }
    ensure_resource('file', '/usr/local/bin/nrpe2nodexp', {
        ensure => 'present',
        source => 'puppet:///modules/nrpe/nrpe2nodexp.py',
        mode   => '0555',
    })

    $ensure_nrpe2nodexp_cond = (($enable_nrpe2nodexp) and ($ensure == 'present') and (debian::codename::ge('bullseye')))
    $ensure_nrpe2nodexp = $ensure_nrpe2nodexp_cond ? {
        true  => 'present',
        false => 'absent'
    }

    $command = $nrpe2nodexp_parse_perf_data ? {
        true  => "/usr/local/bin/nrpe2nodexp --timeout ${timeout} --check-command check_${title} --perf-data",
        false => "/usr/local/bin/nrpe2nodexp --timeout ${timeout} --check-command check_${title}",
    }

    # user nagios needed for privilege escalation
    # group prometheus-node-exporter needed to store the result in /var/lib/prometheus/node.d
    systemd::timer::job { "nrpe2nodexp-${title}":
        ensure            => $ensure_nrpe2nodexp,
        description       => "execution of nrpe2nodexp for the check_${title} command.",
        user              => 'nagios',
        group             => 'prometheus-node-exporter',
        ignore_errors     => true,
        command           => $command,
        interval          => [ { 'start' => 'OnUnitInactiveSec', 'interval' => "${check_interval}min" }, ],
        logging_enabled   => false, #custom rule is configured through a dedicated resource
        syslog_identifier => "nrpe2nodexp-${title}", # Each instance must have a unique value to avoid resource duplication
    }

    # A different SyslogIdentifier is assigned to each check,
    # so we cannot use the rsyslog lookup table to set log_outputs.
    # Instead, we add a custom rule to send the relevant logs to Logstash.
    rsyslog::conf { "nrpe2nodexp-${title}":
        ensure   => $ensure_nrpe2nodexp,
        content  => template('nrpe/nrpe2nodexp.rsyslog.conf.erb'),
        priority => 25,
    }

}
