# SPDX-License-Identifier: Apache-2.0
# Setup a private APT repository, using Apache2.
# The private repository is meant for packages
# which cannot legally be available on the public
# internet.

class role::apt_private_repo {
    include profile::base::production
    include profile::firewall

    include profile::nginx
    include profile::installserver::http
    include profile::aptrepo::private
}
