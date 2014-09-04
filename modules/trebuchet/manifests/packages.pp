# == Class: trebuchet::packages
#
# Provision packages required for trebuchet to operate
#
class trebuchet::packages {
    include stdlib
    ensure_packages(['python-redis', 'git-core', 'git-fat'])
}
