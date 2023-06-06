# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::resource::filter_params' do
  it 'exists' do
    is_expected.not_to be_nil
  end

  describe 'mock resource' do
    before do
      allow(scope).to receive(:resource).and_return({foo: 'foo', bar: 'bar'})
    end
    it 'filter bar' do
      is_expected.to run.with_params('bar').and_return({'foo' => 'foo'})
    end
    it 'filter foo with array' do
      is_expected.to run.with_params(['foo']).and_return({'bar' => 'bar'})
    end
    it 'filter foo and bar' do
      is_expected.to run.with_params('foo', 'bar').and_return({})
    end
    it 'filter foo and bar with array' do
      is_expected.to run.with_params(['foo', 'bar']).and_return({})
    end
  end
end
