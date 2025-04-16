# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::list_secrets' do
  it 'should run correctly with a existing secret directory' do
    is_expected.to run.with_params('test').and_return(["test/README", "test/test.bin", "test/test.txt"])
  end
  it 'should run correctly using a custom pattern' do
    is_expected.to run.with_params('test', 'test.*').and_return(['test/test.bin', 'test/test.txt'])
  end
end
