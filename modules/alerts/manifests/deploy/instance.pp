# Wrap a call to alerts-deploy with a systemd unit.
# The unit is normally not active (one-shot) and will be started when
# alerts-deploy.target is started.
# The .service units need to be enabled for the .target dependencies to
# be setup.

define alerts::deploy::instance (
  String $alerts_dir,
  String $deploy_dir,
  Optional[String] $deploy_tag = undef,
  Optional[Wmflib::Sites] $deploy_site = undef,
) {
    if !defined(File[$deploy_dir]) {
        file { $deploy_dir:
            ensure => directory,
            owner  => 'alerts-deploy',
            group  => 'alerts-deploy',
            mode   => '0755',
        }
    }

    $service_name = "alerts-deploy@${title}"

    systemd::unit { $service_name:
        ensure  => present,
        content => systemd_template('alerts-deploy@'),
        before  => Git::Clone['operations/alerts'],
    }

    exec { "enable ${service_name}":
        command => "/bin/systemctl enable ${service_name}",
        unless  => "/bin/systemctl -q is-enabled ${service_name}",
        require => Systemd::Unit[$service_name],
    }
}
