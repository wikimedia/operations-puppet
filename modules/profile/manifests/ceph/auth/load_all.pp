# SPDX-License-Identifier: Apache-2.0
# This profile deploys and loads to ceph all the known authorizations.
# You only need one of profile::ceph::auth::load_all or profile::ceph::auth::deploy, the first will also deploy all known auths.
class profile::ceph::auth::load_all (
  Ceph::Auth::Conf $configuration = lookup('profile::ceph::auth::load_all::configuration'),
) {
  class { 'ceph::auth::load_all':
    configuration => $configuration,
  }
}
