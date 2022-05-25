# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'sudo::safe_wildcard_cmd' do
  it 'return command as normal if no wild card' do
    is_expected.to run.with_params('/bin/mkdir', '/tmp').and_return('/bin/mkdir /tmp')
  end
  it 'expand to a safe path' do
    is_expected.to run.with_params('/bin/mkdir', '/tmp*').and_return(
      '/bin/mkdir /tmp*, !/bin/mkdir /tmp* *, !/bin/mkdir /tmp*..*'
    )
  end
end
