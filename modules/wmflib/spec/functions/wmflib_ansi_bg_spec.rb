# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::ansi::bg' do
  it { is_expected.to run.with_params('foo', 'red').and_return("\u001B[41mfoo\u001B[0m") }
  it { is_expected.to run.with_params("foo\u001B[0m", 'red').and_return("\u001B[41mfoo\u001B[0m") }
  it { is_expected.to run.with_params('foo', 'red', false).and_return("\u001B[41mfoo") }
end
