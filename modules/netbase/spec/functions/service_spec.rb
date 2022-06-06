# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'netbase::service' do
  it do
    is_expected.to run.with_params('ssh')
      .and_return({'protocols' => ['tcp'], 'port' => 22, 'description' => 'SSH Remote Login Protocol'})
  end
  it do
    is_expected.to run.with_params('domain')
      .and_return({'protocols' => ['tcp', 'udp'], 'port' => 53, 'description' => 'Domain Name Server'})
  end
  it { is_expected.to run.with_params('foobar').and_return(nil) }
end
