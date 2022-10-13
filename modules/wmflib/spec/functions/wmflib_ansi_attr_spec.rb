# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::ansi::attr' do
  it { is_expected.to run.with_params('foo', 'bold').and_return("\u001B[1mfoo\u001B[0m") }
  it { is_expected.to run.with_params("foo\u001B[0m", 'bold').and_return("\u001B[1mfoo\u001B[0m") }
  it { is_expected.to run.with_params('foo', 'bold', false).and_return("\u001B[1mfoo") }
end
