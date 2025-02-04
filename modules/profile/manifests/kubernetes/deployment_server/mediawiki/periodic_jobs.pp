# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::deployment_server::mediawiki::periodic_jobs(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
  concat { "${helmfile_defaults_dir}/mediawiki/periodic-jobs.yaml":
    ensure => present,
    tag    => 'kubernetes_mediawiki_periodic_jobs',
    owner  => 'mwdeploy',
    group  => 'deployment',
    mode   => '0644',
  }
  concat::fragment { 'periodic_jobs_header':
    target  => "${helmfile_defaults_dir}/mediawiki/periodic-jobs.yaml",
    content => "# SPDX-License-Identifier: Apache-2.0\nmwcron:\n  jobs:\n",
    order   => '01',
  }

  include profile::mediawiki::maintenance::serviceops_version

}
