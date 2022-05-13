<!-- SPDX-License-Identifier: Apache-2.0 -->
# Cloudflare SSL module

Acceptance testing can be performed with the following command

`BEAKER_set="debian10" bundle exec rake beaker`

# Notes:

We see the following error in the logs:
  [WARNING] endpoint '/api/v1/cfssl/sign' is disabled: {"code":5200,"message":"Invalid or unknown policy"}

This seems be be caused because all our policies require an `auth_key` as such the default unauthenticated
sign endpoint is not available[1]
[1]https://github.com/cloudflare/cfssl/issues/566#issuecomment-269070807
