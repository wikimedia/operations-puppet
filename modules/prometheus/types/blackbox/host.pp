# SPDX-License-Identifier: Apache-2.0

# @type Prometheus::Blackbox::Host

# Describe metadata for an host to be probed by Blackbox
type Prometheus::Blackbox::Host = Struct[{
    'site'    => Wmflib::Sites,
    'realm'   => String,
    'rack'    => String,
}]
