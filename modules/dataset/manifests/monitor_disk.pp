class dataset::monitor_data_diskspace(
     $pct_warning   = 3,
     $pct_critical  = 2,
) {
     nrpe::monitor_service { 'dataset_disk_space':
         description   => 'Dataset disk space',
         nrpe_command  => "/usr/lib/nagios/plugins/check_disk -w ${pct_warning}% -c ${pct_critical}% -l -e -p /data",
     }
}
