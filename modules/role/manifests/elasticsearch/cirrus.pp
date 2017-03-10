# = Class: role::elasticsearch::cirrus
#
# This class sets up Elasticsearch specifically for CirrusSearch.
#
# filtertags: labs-project-deployment-prep labs-project-search labs-project-math
class role::elasticsearch::cirrus {
    include ::profile::elasticsearch::common
}
