# SPDX-License-Identifier: Apache-2.0
# == Defined type httpbb::test_suite
#
# Resource for httpbb test suite YAML files, which are installed into the
# directory passed as $tests_dir to the httpbb class. That class must be
# declared before any httpbb::test_suite resources.
define httpbb::test_suite(
    Wmflib::Ensure $ensure = 'present',
    Optional[String] $mode = undef,
    Optional[Stdlib::Filesource] $source = undef,
    Optional[String] $content = undef,
){
    if !defined(Class['httpbb']) {
        fail('Declare the httpbb class before using httpbb::test_suite.')
    }

    $path = "${::httpbb::tests_dir}/${title}"

    if $ensure == 'absent' {
        file { $path:
            ensure => absent,
        }
    } elsif $source {
        file { $path:
            ensure => file,
            mode   => $mode,
            source => $source,
        }
    } elsif $content {
        file { $path:
            ensure  => file,
            mode    => $mode,
            content => $content,
        }
    } else {
        fail('Define either source or content, or ensure => absent.')
    }

}
