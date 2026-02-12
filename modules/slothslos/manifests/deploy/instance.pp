# SPDX-License-Identifier: Apache-2.0
# @summary Manage role-independent resources for SlothSLOS deployments
#
# This class creates a directory to store the output of `sloth generate`
# and deploys the script responsible for managing the deployment (`slothslos-deploy.py`).
# It also sets up a systemd target that can be used to trigger
# `slothslos-deploy.py` after the Git repository has been updated.
#
# @param manifests_dir [Stdlib::Unixpath] The directory where manifests are stored.
# @param deploy_dir [Stdlib::Unixpath] The directory where the generated rules will be deployed.
# @param git_repo_name [String] The name of the Git repository to be cloned.
# @param git_repo_branch [String] The branch of the Git repository to be cloned.
# @param ensure [Wmflib::Ensure] Whether the resources should be present or absent.
define slothslos::deploy::instance (
    Stdlib::Unixpath $manifests_dir,
    Stdlib::Unixpath $deploy_dir,
    String[1] $git_repo_name,
    String[1] $git_repo_branch = 'main',
    Wmflib::Ensure $ensure = present,
) {
    if !defined(File[$deploy_dir]) {
        file { $deploy_dir:
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => $slothslos::user,
            group  => $slothslos::user,
            mode   => '0755',
        }
    }

    $service_name = "slothslos-flatten@${title}"

    systemd::unit { $service_name:
        ensure  => $ensure,
        content => systemd_template('slothslos-flatten@'),
        before  => [Git::Clone[$git_repo_name], Systemd::Service["slothslos-flatten@${title}"]],
    }

    systemd::service { $service_name:
        ensure    => $ensure,
        unit_type => 'path',
        content   => systemd_template('slothslos-flatten@.path'),
        team      => 'Observability',
        before    => Git::Clone[$git_repo_name],
    }
}
