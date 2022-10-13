# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::ansi::reset' do
  it { is_expected.to run.with_params('foo').and_return("foo\u001B[0m") }
  it { is_expected.to run.with_params("foo\u001B[0m").and_return("foo\u001B[0m") }
end
