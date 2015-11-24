# XXX this needs to be refactored Elsewhere
# Virtual resources for the monitoring server
@monitoring::group { 'cache_text_codfw': description => 'codfw text Varnish' }
@monitoring::group { 'cache_text_eqiad': description => 'eqiad text Varnish' }
@monitoring::group { 'cache_text_esams': description => 'esams text Varnish' }
@monitoring::group { 'cache_text_ulsfo': description => 'ulsfo text Varnish' }
@monitoring::group { 'cache_upload_codfw': description => 'codfw upload Varnish' }
@monitoring::group { 'cache_upload_eqiad': description => 'eqiad upload Varnish' }
@monitoring::group { 'cache_upload_esams': description => 'esams upload Varnish' }
@monitoring::group { 'cache_upload_ulsfo': description => 'ulsfo upload Varnish' }
@monitoring::group { 'cache_mobile_codfw': description => 'codfw mobile Varnish' }
@monitoring::group { 'cache_mobile_eqiad': description => 'eqiad mobile Varnish' }
@monitoring::group { 'cache_mobile_esams': description => 'esams mobile Varnish' }
@monitoring::group { 'cache_mobile_ulsfo': description => 'ulsfo mobile Varnish' }
@monitoring::group { 'cache_parsoid_codfw': description => 'Parsoid caches codfw' }
@monitoring::group { 'cache_parsoid_eqiad': description => 'Parsoid caches eqiad' }
@monitoring::group { 'cache_misc_codfw': description => 'Misc caches codfw' }
@monitoring::group { 'cache_misc_eqiad': description => 'Misc caches eqiad' }
@monitoring::group { 'cache_misc_esams': description => 'Misc caches esams' }
@monitoring::group { 'cache_misc_ulsfo': description => 'Misc caches ulsfo' }
@monitoring::group { 'cache_maps_eqiad': description => 'Maps caches eqiad' }

# If you're looking for something that used to be here, check modules/role/manifests/cache/...
