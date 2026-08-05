# SPDX-License-Identifier: Apache-2.0
# @summary Common role for scap masters and targets
# @param deployment_server
#    Server that provides git repositories for scap3. Default 'deployment'.
#
# @param wmflabs_master
#    Master scap rsync host in the wmflabs domain.
#    Default 'deployment-deploy04.deployment-prep.eqiad1.wikimedia.cloud'.
# @param is_master indicates if the server is a scap::master
#
# @param manage_logstash_credentials
#    If true, install /etc/scap/logstash_credentials from the private repo and
#    tell scap to use it. Scap then authenticates its logstash queries. Only
#    scap masters query logstash, so the file is installed on masters only.
#
# @param logstash_credentials_group
#    Group that can read the logstash credentials file. Keep this the same as
#    the 'deployment_group' hiera key, since scap runs both as the deployer
#    and as the spiderpig user.
class scap (
    Variant[Stdlib::Host,String] $deployment_server = 'deployment',
    Stdlib::Fqdn $wmflabs_master                    = 'deployment-deploy04.deployment-prep.eqiad1.wikimedia.cloud',
    Stdlib::Port::Unprivileged $php7_admin_port     = 9181,
    Stdlib::Fqdn $betacluster_udplog_host           = 'deployment-mwlog02.deployment-prep.eqiad1.wikimedia.cloud',
    Boolean      $is_master                         = false,
    Optional[Hash] $k8s_deployments                 = {},
    Boolean $enable_bootstrapping                   = true,
    Boolean $manage_logstash_credentials            = false,
    String[1] $logstash_credentials_group           = 'wikidev',
) {
    require git::lfs
    include scap::user

    # Required python3 package is provided by base::standard_packages class
    ensure_packages(['rsync', 'python3-venv'])

    # Deployment servers/masters are bootstrapped in profile::mediawiki::deployment::server
    if $enable_bootstrapping and !$is_master {
        $scap_home = $scap::user::home_dir

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

    # T434114: Credentials for authenticated logstash queries. Only scap
    # masters query logstash.
    $logstash_credentials_file = '/etc/scap/logstash_credentials'
    $use_logstash_credentials = $is_master and $manage_logstash_credentials
    if $use_logstash_credentials {
        wmflib::dir::mkdir_p('/etc/scap')

        file { $logstash_credentials_file:
            ensure    => present,
            owner     => 'root',
            group     => $logstash_credentials_group,
            mode      => '0440',
            content   => secret('scap/logstash_credentials'),
            show_diff => false,
        }
    } else {
        file { $logstash_credentials_file:
            ensure => absent,
        }
    }

    # Disable Scap deployments on the inactive deployment server
    $block_scap_deployments = $is_master and $facts['networking']['fqdn'] != $deployment_server
    file { '/etc/scap.cfg':
        content => template('scap/scap.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
