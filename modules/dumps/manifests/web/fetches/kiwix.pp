class dumps::web::fetches::kiwix(
    $user = undef,
    $group = undef,
    $xmldumpsdir = undef,
    $miscdatasetsdir = undef,
) {
    ensure_packages('rsync')

    file { "${xmldumpsdir}/kiwix":
        ensure => 'link',
        target => "${miscdatasetsdir}/kiwix",
        owner  => $user,
        group  => $group,
        mode   => '0644',
    }

    file { '/usr/local/bin/kiwix-rsync-cron.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/fetches/kiwix-rsync-cron.sh',
    }

    # Stagger download crons based on hostname. The kiwix server
    #  is very touchy about concurrent connections!
    $last_hostname_digit = inline_template('<%= @hostname.gsub(/\D/,"") %>')
    $stagger = (Integer($last_hostname_digit) % 2) * 4

    systemd::timer::job { 'kiwix-mirror-update':
        ensure             => present,
        description        => 'Regular jobs to update kiwix mirror',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/bin/bash /usr/local/bin/kiwix-rsync-cron.sh ${miscdatasetsdir}",
        interval           => {'start' => 'OnCalendar', 'interval' => "*-*-* ${stagger}/8:15:0"},
        require            => File['/usr/local/bin/kiwix-rsync-cron.sh'],
    }
}
