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

    include standard-noexim
    include backup::client
    include misc::fundraising
    include misc::fundraising::backup::backupmover_user

    #monitor_service { 'smtp':
    #    description   => 'Exim SMTP',
    #    check_command => 'check_smtp',
    #}

    #monitor_service { 'http':
    #    description   => 'HTTP',
    #    check_command => 'check_http',
    #}
}
