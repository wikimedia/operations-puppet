# SPDX-License-Identifier: Apache-2.0
# Describes the websites served by Wikimedia's CDN. The hash key is the FQDN of
# the site as sent in the Host request header.
type Profile::Cache::Sites = Hash[String, Struct[{
    'caching'   => Profile::Cache::Caching,
    'regex_key' => Optional[Boolean],
    'subpaths'  => Optional[Hash[String, Struct[{
        'caching'   => Profile::Cache::Caching,
    }]]],
}]]
