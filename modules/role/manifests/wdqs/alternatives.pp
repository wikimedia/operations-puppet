# SPDX-License-Identifier: Apache-2.0
# = Class: role::wdqs::alternatives
#
# This class sets up Wikidata Query Service for testing alternatives to
# Blazegraph. Not exposed to public or private clients.
class role::wdqs::alternatives {
    # Standard for all roles
    include profile::base::production
    include profile::firewall

    include profile::wdqs::alternatives
}
