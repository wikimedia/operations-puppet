# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
base_svc = {
  'base' => {
    'description' => 'example',
    'sites' => ['eqiad'],
    'ip' => { 'eqiad' => { 'ncredirlb' => '208.80.153.232', 'ncredirlb6' => '2620:0:860:ed1a::9' }},
    'port' => 80,
    'encryption' => false,
    'state' => 'production',
    'lvs' => {
      'enabled' => true,
      'bgp' => true,
      'scheduler' => 'mh',
      'class' => 'high-traffic1',
      'conftool' => { 'cluster' => 'foo', 'service' => 'bar' },
      'depool_threshold' => 0.5, 'ipip_encapsulation' => ['eqiad'],
    },
  },
}

describe 'liberica::service_from_wmflib' do
  context "service using ProxyFetch" do
    let('svc') { base_svc.merge('base' => base_svc['base'].merge('lvs' => base_svc['base']['lvs'].merge(
      {'monitors' =>
       {'ProxyFetch' =>
        { 'url' => ['http://www.wikipedia.com/_status'] }
       }
      })))
    }
    it { is_expected.to run.with_params(svc, 'eqiad').and_return(
      {
        'baselb_80' => {
          'forward_type' => 'tunnel',
          'depool_threshold' => 0.5,
          'cluster' => 'foo',
          'service' => 'bar',
          'ip' => '208.80.153.232',
          'port' => 80,
          'protocol' => 'tcp',
          'healthchecks' => {
            'L7-http://www.wikipedia.com/_status' => {
              'type' => 'HTTPCheck',
              'url' => 'http://www.wikipedia.com/_status',
              'status_code' => 200,
              'timeout' => '5s',
              'check_period' => '10s',
            },
          },
        },
        'baselb6_80' => {
          'forward_type' => 'tunnel',
          'depool_threshold' => 0.5,
          'cluster' => 'foo',
          'service' => 'bar',
          'ip' => '2620:0:860:ed1a::9',
          'port' => 80,
          'protocol' => 'tcp',
          'healthchecks' => {
            'L7-http://www.wikipedia.com/_status' => {
              'type' => 'HTTPCheck',
              'url' => 'http://www.wikipedia.com/_status',
              'status_code' => 200,
              'timeout' => '5s',
              'check_period' => '10s',
            },
          },
        },
      }
    ) }
  end
  context "service using IdleConnection" do
    let('svc') { base_svc.merge('base' => base_svc['base'].merge('lvs' => base_svc['base']['lvs'].merge(
      {'monitors' =>
       {'IdleConnection' =>
        { 'timeout' => '3s' }
       }
      })))
    }
    it { is_expected.to run.with_params(svc, 'eqiad').and_return(
      {
        'baselb_80' => {
          'forward_type' => 'tunnel',
          'depool_threshold' => 0.5,
          'cluster' => 'foo',
          'service' => 'bar',
          'ip' => '208.80.153.232',
          'port' => 80,
          'protocol' => 'tcp',
          'healthchecks' => {
            'L4' => {
              'type' => 'IdleTCPConnectionCheck',
              'timeout' => '3s',
              'check_period' => '300ms',
              'reconnect_period' => '1s',
            },
          },
        },
        'baselb6_80' => {
          'forward_type' => 'tunnel',
          'depool_threshold' => 0.5,
          'cluster' => 'foo',
          'service' => 'bar',
          'ip' => '2620:0:860:ed1a::9',
          'port' => 80,
          'protocol' => 'tcp',
          'healthchecks' => {
            'L4' => {
              'type' => 'IdleTCPConnectionCheck',
              'timeout' => '3s',
              'check_period' => '300ms',
              'reconnect_period' => '1s',
            },
          },
        },
      }
    ) }
  end
  context "service using both ProxyFetch and IdleConnection" do
    let('svc') { base_svc.merge('base' => base_svc['base'].merge('lvs' => base_svc['base']['lvs'].merge(
      {'monitors' =>
       {
         'ProxyFetch' => {'url' => ['http://www.wikipedia.com/_status']},
         'IdleConnection' => { 'timeout' => '3s' },
       }
      })))
    }
    it { is_expected.to run.with_params(svc, 'eqiad').and_return(
      {
        'baselb_80' => {
          'forward_type' => 'tunnel',
          'depool_threshold' => 0.5,
          'cluster' => 'foo',
          'service' => 'bar',
          'ip' => '208.80.153.232',
          'port' => 80,
          'protocol' => 'tcp',
          'healthchecks' => {
            'L7-http://www.wikipedia.com/_status' => {
              'type' => 'HTTPCheck',
              'url' => 'http://www.wikipedia.com/_status',
              'status_code' => 200,
              'timeout' => '5s',
              'check_period' => '10s',
            },
            'L4' => {
              'type' => 'IdleTCPConnectionCheck',
              'timeout' => '3s',
              'check_period' => '300ms',
              'reconnect_period' => '1s',
            },
          },
        },
        'baselb6_80' => {
          'forward_type' => 'tunnel',
          'depool_threshold' => 0.5,
          'cluster' => 'foo',
          'service' => 'bar',
          'ip' => '2620:0:860:ed1a::9',
          'port' => 80,
          'protocol' => 'tcp',
          'healthchecks' => {
            'L7-http://www.wikipedia.com/_status' => {
              'type' => 'HTTPCheck',
              'url' => 'http://www.wikipedia.com/_status',
              'status_code' => 200,
              'timeout' => '5s',
              'check_period' => '10s',
            },
            'L4' => {
              'type' => 'IdleTCPConnectionCheck',
              'timeout' => '3s',
              'check_period' => '300ms',
              'reconnect_period' => '1s',
            },
          },
        },
      }
    ) }
  end
end
