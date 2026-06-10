# SPDX-License-Identifier: Apache-2.0
# = Class: role::cirrussearch::beta
#
# This class sets up OpenSearch specifically for CirrusSearch on deployment-prep.
#
class role::cirrus::beta {
    include profile::opensearch::cirrus::deployment_prep
}
