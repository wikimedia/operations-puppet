#Monitor the Etherpad process.
class etherpad::monitoring{

    # Icinga process monitoring, RT #5790
    monitor_service { 'etherpad-lite-proc':
        description   => 'etherpad_lite_process_running',
        check_command => 'nrpe_check_etherpad_lite',
    }
}
