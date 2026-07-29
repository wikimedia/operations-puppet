# SPDX-License-Identifier: Apache-2.0
# @summary type to validate buildkitd OCI worker snapshotter names
type Buildkitd::Snapshotter = Enum['auto', 'fuse-overlayfs', 'native', 'overlayfs', 'stargz']
