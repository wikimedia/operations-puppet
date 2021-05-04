# Ceph storage cluster monitoring for CloudVPS
class profile::ceph::alerts(
) {
    # Check the global Ceph cluster health
    monitoring::check_prometheus { 'cloudvps_ceph_health':
        description     => 'Ceph Cluster Health',
        query           => 'ceph_health_status{job="ceph_eqiad"}',
        prometheus_url  => 'http://prometheus-labmon.eqiad.wmnet/labs',
        retries         => 2,
        warning         => 1,
        critical        => 2,
        contact_group   => 'wmcs-team',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/cloudvps-ceph-cluster'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Alerts#Ceph_Cluster_Health',
    }

    # Check the global Ceph mon quorum count
    monitoring::check_prometheus { 'cloudvps_ceph_mon_quorum':
        description     => 'Ceph Mon Quorum',
        query           => 'sum(ceph_mon_quorum_status{job="ceph_eqiad"})',
        prometheus_url  => 'http://prometheus-labmon.eqiad.wmnet/labs',
        retries         => 2,
        warning         => 1,
        critical        => 0,
        method          => 'le',
        contact_group   => 'wmcs-team',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/cloudvps-ceph-cluster'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Alerts#Ceph_Mon_Quorum',
    }

    # Check the global count of down Ceph OSDs
    monitoring::check_prometheus { 'cloudvps_ceph_osd_down':
        description     => 'Ceph OSDs Down',
        query           => 'count(ceph_osd_up{job="ceph_eqiad"} == 0)',
        prometheus_url  => 'http://prometheus-labmon.eqiad.wmnet/labs',
        retries         => 2,
        warning         => 1,
        critical        => 8,
        contact_group   => 'wmcs-team',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/cloudvps-ceph-cluster'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Alerts#Ceph_Osds_Down',
    }
}
