@monitor_group { 'fundraising_eqiad':
    description => 'fundraising eqiad',
}

@monitor_group { 'fundraising_pmtpa':
    description => 'fundraising pmtpa',
}

class role::fundraising::civicrm {
    # variables used in fundraising exim template
    $exim_signs_dkim = true
    $exim_bounce_collector = true

    $cluster = 'fundraising'
    $nagios_group = "${cluster}_${::site}"

    sudo_user { 'khorn':
        privileges => ['ALL = NOPASSWD: ALL'],
    }

    $gid = 500
    include standard-noexim
    # include accounts::mhernandez # migrated to lutetium
    # include accounts::zexley # migrated to lutetium
    # include accounts::pcoombe # migrated to lutetium
    include admins::fr-tech
    include admins::roots
    include backup::client
    include misc::fundraising
    include misc::fundraising::backup::backupmover_user
    include misc::fundraising::mail
    include nrpe

    monitor_service { 'smtp':
        description   => 'Exim SMTP',
        check_command => 'check_smtp',
    }

    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}
