# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::cidr_last_address' do
  it 'exists' do
    is_expected.not_to be_nil
  end

  context 'when called with no parameters' do
    it { is_expected.to run.with_params.and_raise_error(ArgumentError) }
  end

  context 'when called with a Integer' do
    it { is_expected.to run.with_params(42).and_raise_error(ArgumentError) }
  end

  context 'when called with a String thats not an ip address' do
    it { is_expected.to run.with_params('42').and_raise_error(ArgumentError) }
  end

  context 'when called with an IPv4 Address that is not in the CIDR notation' do
    it { is_expected.to run.with_params('127.0.0.1').and_raise_error(ArgumentError) }
  end

  context 'when called with an IPv6 Address that is not in the CIDR notation' do
    it { is_expected.to run.with_params('fe80::800:27ff:fe00:0').and_raise_error(ArgumentError) }
  end

  context 'when called with an IPv4 CIDR' do
    it { is_expected.to run.with_params('192.0.2.0/24').and_return('192.0.2.255') }
  end

  context 'when called with an IPv6 CIDR' do
    it { is_expected.to run.with_params('fe80::800:27ff:fe00:0/64').and_return('fe80::ffff:ffff:ffff:ffff') }
  end
end
