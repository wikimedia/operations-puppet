# == Class profile::analytics::refinery::repository
#
# Deploy the analytics/refinery repository without any
# Hadoop or Mediawiki dependency. This profile is meant to be
# mostly used as part of profile::analytics::refinery, but it
# may also be deployed to hosts that don't need the full Refinery
# potential but only a specific subset (for example, the eventlogging
# database hosts need a whitelist file to purge data correctly, without
# the need to install a ton of Hadoop packages).
#
class profile::analytics::refinery::repository {
    # The analytics/refinery repo will deployed to this node via Scap3.
    # The analytics user/groups are deployed/managed by Scap.
    # The analytics_deploy SSH keypair files are stored in the private repo,
    # and since manage_user is true the analytics_deploy public ssh key
    # will be added to the 'analytics-deploy' user's ssh config. The rationale is to
    # have a single 'analytics' multi-purpose user that owns refinery files
    # deployed via scap and could possibly do other things (not yet defined).
    scap::target { 'analytics/refinery':
        deploy_user => 'analytics-deploy',
        key_name    => 'analytics_deploy',
        manage_user => true,
    }

    # analytics/refinery repository is deployed via git-deploy at this path.
    # You must deploy this yourself; puppet will not do it for you.
    $path = '/srv/deployment/analytics/refinery'

    # Put refinery python module in user PYTHONPATH
    file { '/etc/profile.d/refinery.sh':
        content => "export PYTHONPATH=\${PYTHONPATH}:${path}/python",
    }
}
