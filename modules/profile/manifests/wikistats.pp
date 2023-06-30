# https://wikistats.wmcloud.org
#
# This is a historic cloud-only project.
#
# It is NOT stats.wikimedia.org or wikistats2
# run by the WMF Analytics team.
#
# These projects are unrelated despite the
# similar names.
#
# maintainer: dzahn
# phabricator-tag: VPS-project-Wikistats
class profile::wikistats (
    Wmflib::Ensure $jobs_ensure = lookup('profile::wikistats::jobs_ensure', {default_value => 'present'}),
){

    motd::script { 'deployment_info':
        ensure   => present,
        priority => 1,
        content  => template('wikistats/deployment_info.motd.erb'),
    }

    class { '::wikistats':
        jobs_ensure    => $jobs_ensure,
    }
}
