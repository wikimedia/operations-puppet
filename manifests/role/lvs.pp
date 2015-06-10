# role/lvs.pp

@monitoring::group { "lvs": description => "LVS" }
@monitoring::group { "lvs_eqiad": description => "eqiad LVS servers" }
@monitoring::group { "lvs_codfw": description => "codfw LVS servers" }
@monitoring::group { "lvs_ulsfo": description => "ulsfo LVS servers" }
@monitoring::group { "lvs_esams": description => "esams LVS servers" }
