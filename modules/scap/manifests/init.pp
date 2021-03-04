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
#    Default 'deployment-deploy01.deployment-prep.eqiad1.wikimedia.cloud'.
class scap (
    Variant[Stdlib::Host,String] $deployment_server = 'deployment',
    Stdlib::Fqdn $wmflabs_master                    = 'deployment-deploy01.deployment-prep.eqiad1.wikimedia.cloud',
    String $version                                 = 'present',
    Stdlib::Port::Unprivileged $php7_admin_port     = 9181,
    Stdlib::Fqdn $cloud_statsd_host                 = 'cloudmetrics1002.eqiad.wmnet',
    Stdlib::Fqdn $betacluster_udplog_host           = 'deployment-mwlog01.deployment-prep.eqiad1.wikimedia.cloud',
) {
    require git::lfs

    package { 'scap':
        ensure => $version,
    }

    file { '/etc/scap.cfg':
        content => template('scap/scap.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    ensure_packages([
        'python-psutil',
        'python-netifaces',
        'python-yaml',
        'python-requests',
        'python-jinja2',
    ])
}
