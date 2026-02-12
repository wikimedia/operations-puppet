# SPDX-License-Identifier: Apache-2.0
# @summary Manage Thanos-specific resources for SlothSLOS deployments
#
# @param ensure [Wmflib::Ensure] Whether the resources should be
#   present or absent.
# @param deploy_dir [Stdlib::Unixpath] The directory where the generated
#   rules will be deployed.
# @param git_dir [Stdlib::Unixpath] The directory where the Git repository
#   will be cloned.
# @param git_repo_name [String] The name of the Git repository to be cloned.
# @param git_repo_branch [String] The branch of the Git repository to be cloned.
# @param git_repo_source [String] The source of the Git repository
#   (e.g., gitlab, gerrit).
# @param thanos_ruler_instance [String] The name of the Thanos Ruler instance
#   to be reloaded after a successful deploy.
define slothslos::deploy::thanos (
    Wmflib::Ensure $ensure = present,
    Stdlib::Unixpath $deploy_dir = "/srv/slothslos@${title}",
    Stdlib::Unixpath $git_dir = '/srv/slothslos.git',
    String[1] $git_repo_name = 'repos/sre/slothslos',
    String[1] $git_repo_branch = 'main',
    String[1] $git_repo_source = 'gitlab',
    String[1] $thanos_ruler_instance = 'main',
) {
    require slothslos

    slothslos::deploy::instance { $title:
        ensure          => $ensure,
        deploy_dir      => $deploy_dir,
        git_repo_name   => $git_repo_name,
        git_repo_branch => $git_repo_branch,
        manifests_dir   => $git_dir,
    }

    $git_clone_ensure = $ensure ? {
        'present' => latest,
        'absent'  => absent,
    }
    git::clone { $git_repo_name:
        ensure    => $git_clone_ensure,
        directory => $git_dir,
        branch    => $git_repo_branch,
        source    => $git_repo_source,
    }
}
