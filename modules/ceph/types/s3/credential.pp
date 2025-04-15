# SPDX-License-Identifier: Apache-2.0
# Credential for S3 endpoints in Ceph, needs a access_key and a secret_key.

# Key lengths taken from src/rgw/driver/rados/rgw_user.h in the Ceph source
type Ceph::S3::Credential = Struct[{
    access_key => String,
    secret_key => String,
}]
