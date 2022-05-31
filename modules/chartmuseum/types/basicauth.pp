# SPDX-License-Identifier: Apache-2.0
# ChartMuseum::BasicAuth configures username and password to be used for HTTP
# basic authentication in ChartMuseum.
#
type ChartMuseum::BasicAuth = Struct[{
    'username' => String[1],
    'password' => String[1],
}]
