class role::backup::host {
    include role::backup::config

    $pool = $role::backup::config::pool

    class { 'bacula::client':
        director       => $role::backup::config::director,
        catalog        => 'production',
        file_retention => '60 days',
        job_retention  => '60 days',
    }


    # This will use uniqueid fact to distribute (hopefully evenly) machines on
    # days of the week
    $days = $role::backup::config::days
    $day = inline_template('<%= @days[[@uniqueid].pack("H*").unpack("L")[0] % 7] -%>')

    $jobdefaults = "Monthly-1st-${day}-${pool}"

    Bacula::Client::Job <| |> {
        require => Class['bacula::client'],
    }
    File <| tag == 'backup-motd' |>

    # If the machine includes ::base::firewall then let director connect to us
    ferm::service { 'bacula-file-demon':
        proto  => 'tcp',
        port   => '9102',
        srange => "(${role::backup::config::director_ip} ${role::backup::config::director_ip6})",
    }
}

