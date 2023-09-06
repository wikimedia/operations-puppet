# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
test_domain = ['wikimedia-dns.org']
test_ips = ['185.71.138.138', '2001:67c:930::1'].sort

describe 'wmflib::hosts2ips' do
  it { is_expected.to run.with_params(test_domain).and_return(test_ips) }
  it do
    is_expected.to run.with_params(test_domain + ['192.0.2.1'])
      .and_return((test_ips + ['192.0.2.1']).sort)
  end
end
