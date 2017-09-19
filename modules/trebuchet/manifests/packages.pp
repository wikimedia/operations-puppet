# == Class: trebuchet::packages
#
# Provision packages required for trebuchet to operate
#
class trebuchet::packages {
    include ::redis::client::python
}
