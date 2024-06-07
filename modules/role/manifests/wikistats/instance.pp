# role to setup a wikistats instance on a cloud VPS
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
class role::wikistats::instance {
    require profile::wikistats
    require profile::wikistats::db
    require profile::wikistats::httpd
}
