# = Class: role::elasticsearch::beta
#
# This class sets up Elasticsearch specifically for CirrusSearch on deplyoment-prep.
#
class role::elasticsearch::beta {
    include profile::elasticsearch::cirrus
}
