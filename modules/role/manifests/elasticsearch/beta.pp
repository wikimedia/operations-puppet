# = Class: role::elasticsearch::beta
#
# This class sets up Elasticsearch specifically for CirrusSearch on deplyoment-prep.
#
# filtertags: labs-project-deployment-prep labs-project-search labs-project-math
class role::elasticsearch::beta {
    include ::profile::elasticsearch
}
