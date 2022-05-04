# == Class: scap
#
# Common role for scap masters and targets
#
# == Parameters:
#  [*deployment_server*]
#    Server that provides git repositories for scap3. Default 'deployment'.
#
#  [*wmflabs_master*]
#    Master scap rsync host in the wmflabs domain.
#    Default 'deployment-deploy03.deployment-prep.eqiad1.wikimedia.cloud'.
class scap (
    Variant[Stdlib::Host,String] $deployment_server = 'deployment',
    Stdlib::Fqdn $wmflabs_master                    = 'deployment-deploy03.deployment-prep.eqiad1.wikimedia.cloud',
    String $version                                 = 'present',
    Stdlib::Port::Unprivileged $php7_admin_port     = 9181,
    Stdlib::Fqdn $cloud_statsd_host                 = 'cloudmetrics1004.eqiad.wmnet',
    Stdlib::Fqdn $betacluster_udplog_host           = 'deployment-mwlog01.deployment-prep.eqiad1.wikimedia.cloud',
    Optional[Hash] $k8s_deployments                 = {},
) {
    require git::lfs
    include scap::user

    package { 'scap':
        ensure => $version,
    }

    $deploy_k8s = !$k8s_deployments.empty
    $k8s_releases_dir = pick($k8s_deployments['releases_dir'], '/etc/mediawiki/releases')
    $k8s_clusters = $k8s_deployments['clusters']
    $k8s_deployments_file = $k8s_deployments['file']
    file { '/etc/scap.cfg':
        content => template('scap/scap.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
