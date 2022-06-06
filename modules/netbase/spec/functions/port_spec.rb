# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'netbase::port' do
  it do
    is_expected.to run.with_params(22)
      .and_return({'protocols' => ['tcp'], 'port' => 22, 'description' => 'SSH Remote Login Protocol'})
  end
  it do
    is_expected.to run.with_params(53)
      .and_return({'protocols' => ['tcp', 'udp'], 'port' => 53, 'description' => 'Domain Name Server'})
  end
  it { is_expected.to run.with_params(65_000).and_return(nil) }
end
