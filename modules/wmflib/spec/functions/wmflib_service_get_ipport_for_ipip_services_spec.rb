# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
services = {
  'service' => {
    'description' => 'example',
    'sites' => ['eqiad'],
    'ip' => { 'eqiad' => { 'default' => '192.0.2.1' }},
    'port' => 80,
    'encryption' => false,
    'state' => 'production',
    'lvs' => {
      'enabled' => true,
      'class' => 'high-traffic1',
      'conftool' => { 'cluster' => 'foo', 'service' => 'bar' },
      'depool_threshold' => 0.5, 'ipip_encapsulation' => ['eqiad']
    },
  },
  'service-https' => {
    'description' => 'example',
    'sites' => ['eqiad'],
    'ip' => { 'eqiad' => { 'default' => '192.0.2.1' }},
    'port' => 443,
    'encryption' => true,
    'state' => 'production',
    'lvs' => {
      'enabled' => true,
      'class' => 'high-traffic1',
      'conftool' => { 'cluster' => 'foo', 'service' => 'bar' },
      'depool_threshold' => 0.5, 'ipip_encapsulation' => ['eqiad']
    },
  },
}
describe 'wmflib::service::get_ipport_for_ipip_services' do
  it { is_expected.to run.with_params(services, 'eqiad').and_return(["192.0.2.1:443", "192.0.2.1:80"]) }
end
