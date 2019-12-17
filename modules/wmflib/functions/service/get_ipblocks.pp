function wmflib::service::get_ipblocks() >> Hash {
    wmflib::service::fetch().map |$k, $v| {
        [$k, wmflib::service::lvs_ipblock($v['ip'])]
    }
    .reduce({}) |$memo, $element| {$memo + {$element[0] => $element[1]}}
}
