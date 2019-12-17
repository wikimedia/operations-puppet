# Returns a hash corresponding to what was created by lvs::configuration::lvs_services
#
function wmflib::service::get_lvs_services() >> Hash {
    wmflib::service::fetch().map |$lvs_name, $data| {
        if $data['monitoring'] {
            $icinga = {'icinga' => wmflib::service::lvs_icinga($data['monitoring'])}
        }
        else {
            $icinga = {}
        }
        # bgp is announced by default.
        $bgp =  $data['lvs']['bgp']? {
            false   => {'bgp' => 'no'},
            default => {},
        }
        # TCP is the default protocol
        $protocol = $data['lvs']['protocol']? {
            'udp'   => {'protocol' => 'udp'},
            default => {},
        }
        [
            $lvs_name,
            {
            'description'      => $data['description'],
            'class'            => $data['lvs']['class'],
            'sites'            => $data['sites'],
            'port'             => $data['port'],
            'ip'               => wmflib::service::lvs_ipblock($data['ip']),
            'scheduler'        => $data['lvs']['scheduler'],
            'depool-threshold' => $data['lvs']['depool_threshold'],
            'conftool'         => $data['lvs']['conftool'],
            'monitors'         => $data['lvs']['monitors'],
            } + $protocol + $bgp + $icinga
        ]
    }
    .reduce({}) |$memo, $element| { $memo + {$element[0] => $element[1]}}
}
