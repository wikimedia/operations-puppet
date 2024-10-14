# SPDX-License-Identifier: Apache-2.0
class role::kubernetes::worker {
    include profile::base::production
    include profile::firewall

    # Setup dfdaemon (needs to be included before the container runtime)
    include profile::dragonfly::dfdaemon
    # Sets up docker on the machine
    include profile::docker::engine
    # Setup kubernetes stuff
    include profile::kubernetes::node
    # Set up mediawiki-related stuff
    include profile::kubernetes::mediawiki_runner
    # Setup calico
    include profile::calico::kubernetes
    # Setup LVS
    include profile::lvs::realserver
}
