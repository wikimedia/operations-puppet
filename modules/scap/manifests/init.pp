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
    Boolean $enable_bootstrapping                   = true,
) {
    require git::lfs
    include scap::user

    # Required python3 package is provided by base::standard_packages class
    ensure_packages(['rsync'])

    if $enable_bootstrapping {
        # This dir needs to match the home of the user defined in class scap::user
        $scap_home = '/var/lib/scap'

        file { '/usr/local/bin/bootstrap-scap-target.sh':
          mode   => '0755',
          owner  => 'root',
          group  => 'root',
          source => 'puppet:///modules/scap/bootstrap-scap-target.sh',
        }

        exec { 'bootstrap-scap-target':
          command => "/usr/local/bin/bootstrap-scap-target.sh ${deployment_server} ${scap_home}",
          user    => 'scap',
          creates => "${scap_home}/scap/bin/scap",
          require => File['/usr/local/bin/bootstrap-scap-target.sh']
        }

        file { '/usr/bin/scap':
          ensure  => 'link',
          target  => "${scap_home}/scap/bin/scap",
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          require => Exec['bootstrap-scap-target']
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
