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
    Stdlib::Port::Unprivileged $php7_admin_port     = 9181,
    Stdlib::Fqdn $cloud_statsd_host                 = 'cloudmetrics1004.eqiad.wmnet',
    Stdlib::Fqdn $betacluster_udplog_host           = 'deployment-mwlog01.deployment-prep.eqiad1.wikimedia.cloud',
    Optional[Hash] $k8s_deployments                 = {},
    # TODO: drop this parameters as its not used but also needs to be removed from any callers of this class
    String $version                                 = 'present'
) {
    require git::lfs
    include scap::user

    # Required python3 package is provided by base::standard_packages class
    ensure_packages(['rsync'])

    # For the time being, exclude beta cluster hosts (deployment-prep)
    if $::realm == 'production' {
        package { 'scap':
          ensure => 'absent',
        }

        file { '/usr/bin/scap':
          ensure => 'link',
          # The target pointed to here should be in the home of the user defined in class scap::user
          target => '/var/lib/scap/scap/bin/scap',
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
        }
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
