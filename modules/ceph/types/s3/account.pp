# SPDX-License-Identifier: Apache-2.0
# Account for S3 endpoints in Ceph, has a Hash[String, Ceph::S3::Credential].

type Ceph::S3::Account = Hash[String, Ceph::S3::Credential]
