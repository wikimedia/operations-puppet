# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::cidr2mask' do
  it { is_expected.to run.with_params('192.168.2.0/24').and_return('255.255.255.0') }
  it { is_expected.to run.with_params('2620:0:861:1::/64').and_return('ffff:ffff:ffff:ffff::') }
end
