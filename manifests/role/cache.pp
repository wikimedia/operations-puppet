# XXX this needs to be refactored Elsewhere
# Virtual resources for the monitoring server
@monitoring::group { 'cache_text_eqiad': description => 'eqiad text Varnish' }
@monitoring::group { 'cache_text_esams': description => 'esams text Varnish' }
@monitoring::group { 'cache_text_ulsfo': description => 'ulsfo text Varnish' }
@monitoring::group { 'cache_upload_eqiad': description => 'eqiad upload Varnish' }
@monitoring::group { 'cache_upload_esams': description => 'esams upload Varnish' }
@monitoring::group { 'cache_upload_ulsfo': description => 'ulsfo upload Varnish' }
@monitoring::group { 'cache_bits_eqiad': description => 'eqiad bits Varnish' }
@monitoring::group { 'cache_bits_esams': description => 'esams bits Varnish' }
@monitoring::group { 'cache_bits_ulsfo': description => 'ulsfo bits Varnish' }
@monitoring::group { 'cache_mobile_eqiad': description => 'eqiad mobile Varnish' }
@monitoring::group { 'cache_mobile_esams': description => 'esams mobile Varnish' }
@monitoring::group { 'cache_mobile_ulsfo': description => 'ulsfo mobile Varnish' }
@monitoring::group { 'cache_parsoid_eqiad': description => 'Parsoid caches eqiad' }
@monitoring::group { 'cache_misc_eqiad': description => 'Misc caches eqiad' }
