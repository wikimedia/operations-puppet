# SPDX-License-Identifier: Apache-2.0
# old bacula director, which had its own custom storage
# to be decommissioned
class role::backup::olddirector {
    include profile::base::production

    # We actually want to be able to backup ourselves
    include profile::backup::host
    include profile::backup::storage::oldmain
}
