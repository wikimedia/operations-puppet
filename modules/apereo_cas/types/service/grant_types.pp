# SPDX-License-Identifier: Apache-2.0
# @summary The OAuth 2.0 grant types that an OidcRegisteredService can permit.
#   This list contains only the grant types that the services use now.
#   To permit a different grant type, add it here. The values that CAS 7.3
#   supports are in OAuth20GrantTypes.
#   The list for a service must not be empty, because CAS permits all grant
#   types when a service does not list any.
type Apereo_cas::Service::Grant_types = Array[Enum[
    'authorization_code',
    'urn:ietf:params:oauth:grant-type:device_code'
], 1]
