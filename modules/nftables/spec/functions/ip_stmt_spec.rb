# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'nftables::ip_stmt' do
  it 'no filters' do
    is_expected.to run.with_params(4, nil, nil, nil, nil)
      .and_return([])
  end

  it 'source IP address filter' do
    is_expected.to run.with_params(4, ['192.0.2.1'], nil, nil, nil)
      .and_return([['ip saddr { 192.0.2.1 }']])
    is_expected.to run.with_params(4, ['192.0.2.1', 'fe80::123'], nil, nil, nil)
      .and_return([['ip saddr { 192.0.2.1 }']])
  end

  it 'source and destination IP address filter' do
    is_expected.to run.with_params(4, ['192.0.2.1'], ['192.0.2.2'], nil, nil)
      .and_return([['ip saddr { 192.0.2.1 }', 'ip daddr { 192.0.2.2 }']])
    is_expected.to run.with_params(4, ['192.0.2.1', 'fe80::123'], ['192.0.2.2', 'fe80::456'], nil, nil)
      .and_return([['ip saddr { 192.0.2.1 }', 'ip daddr { 192.0.2.2 }']])
  end

  it 'source IP address and destination set filter' do
    is_expected.to run.with_params(4, ['192.0.2.1'], nil, nil, ['FOO_NETWORKS'])
      .and_return([['ip saddr { 192.0.2.1 }', 'ip daddr @FOO_NETWORKS_ipv4']])
    is_expected.to run.with_params(4, ['192.0.2.1', 'fe80::123'], nil, nil, ['FOO_NETWORKS'])
      .and_return([['ip saddr { 192.0.2.1 }', 'ip daddr @FOO_NETWORKS_ipv4']])
  end

  it 'source sets only' do
    is_expected.to run.with_params(4, nil, nil, ['FOO_NETWORKS', 'BAR_NETWORKS'], nil)
      .and_return([
        ['ip saddr @FOO_NETWORKS_ipv4'],
        ['ip saddr @BAR_NETWORKS_ipv4']
      ])
  end

  it 'destination sets only' do
    is_expected.to run.with_params(4, nil, nil, nil, ['FOO_NETWORKS', 'BAR_NETWORKS'])
      .and_return([
        ['ip daddr @FOO_NETWORKS_ipv4'],
        ['ip daddr @BAR_NETWORKS_ipv4']
      ])
  end

  it 'source IP address and destination IP address and set filter' do
    is_expected.to run.with_params(4, ['192.0.2.1'], ['192.0.2.2'], nil, ['FOO_NETWORKS'])
      .and_return([
        ['ip saddr { 192.0.2.1 }', 'ip daddr { 192.0.2.2 }'],
        ['ip saddr { 192.0.2.1 }', 'ip daddr @FOO_NETWORKS_ipv4'],
      ])
    is_expected.to run.with_params(4, ['192.0.2.1', 'fe80::123'], ['192.0.2.2', 'fe80::456'], nil, ['FOO_NETWORKS'])
      .and_return([
        ['ip saddr { 192.0.2.1 }', 'ip daddr { 192.0.2.2 }'],
        ['ip saddr { 192.0.2.1 }', 'ip daddr @FOO_NETWORKS_ipv4'],
      ])
  end

  it 'source IP address and set and destination IP address and set filter' do
    is_expected.to run.with_params(4, ['192.0.2.1'], ['192.0.2.2'], ['SOME_NETWORKS'], ['FOO_NETWORKS'])
      .and_return([
        ['ip saddr { 192.0.2.1 }', 'ip daddr { 192.0.2.2 }'],
        ['ip saddr { 192.0.2.1 }', 'ip daddr @FOO_NETWORKS_ipv4'],
        ['ip saddr @SOME_NETWORKS_ipv4', 'ip daddr { 192.0.2.2 }'],
        ['ip saddr @SOME_NETWORKS_ipv4', 'ip daddr @FOO_NETWORKS_ipv4'],
      ])
    is_expected.to run.with_params(4, ['192.0.2.1', 'fe80::123'], ['192.0.2.2', 'fe80::456'], ['SOME_NETWORKS'], ['FOO_NETWORKS'])
      .and_return([
        ['ip saddr { 192.0.2.1 }', 'ip daddr { 192.0.2.2 }'],
        ['ip saddr { 192.0.2.1 }', 'ip daddr @FOO_NETWORKS_ipv4'],
        ['ip saddr @SOME_NETWORKS_ipv4', 'ip daddr { 192.0.2.2 }'],
        ['ip saddr @SOME_NETWORKS_ipv4', 'ip daddr @FOO_NETWORKS_ipv4'],
      ])
  end

  describe 'no rules should be opened' do
    it 'wrong family source IP' do
      is_expected.to run.with_params(4, ['fe80::123'], nil, nil, nil)
        .and_return([])
    end

    it 'wrong family source IP, correct family destination IP' do
      is_expected.to run.with_params(4, ['fe80::123'], ['192.0.2.2'], nil, nil)
        .and_return([])
      is_expected.to run.with_params(4, ['fe80::123'], ['192.0.2.2', 'fe80::456'], nil, nil)
        .and_return([])
    end

    it 'wrong family source IP, set destination' do
      is_expected.to run.with_params(4, ['fe80::123'], nil, nil, ['FOO_NETWORKS'])
        .and_return([])
    end
    it 'wrong family source IP, correct family destination IP and set destination' do
      is_expected.to run.with_params(4, ['fe80::123'], ['192.0.2.2'], nil, ['FOO_NETWORKS'])
        .and_return([])
    end
  end
end
