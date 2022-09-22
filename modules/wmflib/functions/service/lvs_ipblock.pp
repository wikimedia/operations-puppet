# Given an ip block, return it in the format used by profile::lvs::configuration
function wmflib::service::lvs_ipblock(Hash[String,Wmflib::Service::Ipblock] $block) >> Hash {
    $block.map |$site, $ipblock| {
        if length($ipblock) == 1 {
            [$site, $ipblock.values()[0]]
        }
        else {
            [$site, $ipblock]
        }
    }
    .reduce({}) |$memo, $element| { $memo + {$element[0] => $element[1]}}
}
