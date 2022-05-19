# SPDX-License-Identifier: Apache-2.0
# @summary custom HTTP headers returned by dnsdist's webserver
#
# @param Dnsdist::Http_headers a hash of header name and value

type Dnsdist::Http_headers = Hash[String[1], String[1]]
