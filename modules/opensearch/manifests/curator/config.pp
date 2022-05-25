# SPDX-License-Identifier: Apache-2.0
define opensearch::curator::config(
    Wmflib::Ensure   $ensure  = present,
    Optional[String] $content = undef,
    Optional[String] $source  = undef,
) {
    file { "/etc/curator/${title}.yaml":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

}
