# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
probe_present = {
  'description' => 'example',
  'sites' => ['eqiad'],
  'ip' => { 'eqiad' => { 'default' => '192.0.2.1' }},
  'port' => 443,
  'encryption' => true,
  'state' => 'service_setup',
  'probes' => [
    {
      'type' => 'http',
      'timeout' => '30s'
    }
  ]
}
probe_missing = probe_present.dup
probe_missing.delete('probes')
describe 'wmflib::service::probe::module_options' do
  it { is_expected.to run.with_params('foobar', probe_present).and_return({'timeout' => '30s'}) }
  it { is_expected.to run.with_params('foobar', probe_missing).and_return({'timeout' => '3s'}) }
end
