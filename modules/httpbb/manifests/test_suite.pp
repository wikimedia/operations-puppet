# == Defined type httpbb::test_suite
#
# Resource for httpbb test suite YAML files, which are installed into the
# directory passed as $tests_dir to the httpbb class. That class must be
# declared before any httpbb::test_suite resources.
define httpbb::test_suite(
    Wmflib::Sourceurl $source,
){
    if !defined(Class['httpbb']) {
        fail('Declare the httpbb class before using httpbb::test_suite.')
    }

    file {"${::httpbb::tests_dir}/${title}":
        ensure => file,
        source => $source,
    }
}
