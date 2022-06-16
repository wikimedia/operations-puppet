# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::service::fetch' do
  it { is_expected.to run.with_params }
  it { is_expected.to run.with_params(true) }
end
