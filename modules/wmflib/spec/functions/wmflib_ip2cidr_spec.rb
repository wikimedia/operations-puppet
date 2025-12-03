# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::ip2cidr' do
  it { is_expected.to run.with_params('192.0.2.1').and_return('192.0.2.1/32') }
  it { is_expected.to run.with_params('192.0.2.0/25').and_return('192.0.2.0/25') }
  it { is_expected.to run.with_params('2001:db8::123').and_return('2001:db8::123/128') }
  it { is_expected.to run.with_params('2001:db8:123::/64').and_return('2001:db8:123::/64') }
end
