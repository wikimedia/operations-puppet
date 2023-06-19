# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
describe 'wmflib::mask2cidr' do
  it { is_expected.to run.with_params('255.255.255.0').and_return(24) }
  it { is_expected.to run.with_params('0.0.0.0').and_return(0) }
  it { is_expected.to run.with_params('ffff:ffff:ffff:ffff::').and_return(64) }
end
