class labstore::monitoring::volumes (
    Array[String] $server_vols,
    String $contact_groups='wmcs-team-email,admins',
    String $drbd_role='primary',
){
    if $drbd_role == 'primary' {
        $server_vols.each | $vol | {
            ::nrpe::monitor_service { "NFS_space_${vol}":
                description     => "NFS Share Volume Space ${vol}",
                nrpe_command    => "/usr/lib/nagios/plugins/check_disk -w 20% -c 15% -W 15% -K 10% -l -p ${vol}",
                notes_url       => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Shared_storage#NFS_volume_cleanup',
                dashboard_links => ['https://grafana.wikimedia.org/d/50z0i4XWz/tools-overall-nfs-storage-utilization?orgId=1'],
                check_interval  => 20,
                retry_interval  => 5,
                contact_group   => $contact_groups,
            }
        }
    }
}
