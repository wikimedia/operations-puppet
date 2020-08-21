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
# filtertags: labs-project-wikistats
class profile::wikistats {

    motd::script { 'deployment_info':
        ensure   => 'present',
        priority => 1,
        content  => template('wikistats/deployment_info.motd.erb'),
    }

    class { '::wikistats':
        wikistats_host => $::fqdn,
    }
}
