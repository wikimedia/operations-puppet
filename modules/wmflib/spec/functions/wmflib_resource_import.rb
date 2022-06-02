# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::resource::import' do
  let(:pre_condition) do
    "function puppetdb_query($pql) {
      [
        {
          'title' => 'wmflib::resource||foo',
          'parameters' => { 'content' => 'foo' }
        },
        {
          'title' => 'wmflib::resource||bar',
          'parameters' => { 'content' => 'bar' }
        },
        {
          'title' => 'wmflib::resource||foo',
          'parameters' => { 'content' => 'bar' }
        }
      ]
    }
    "
  end
  let(:result) {{'foo' => { 'content' => 'bar' }, 'bar' => { 'content' => 'bar' } }}
  let(:result_merge) {{'foo' => { 'content' => 'foobar' }, 'bar' => { 'content' => 'bar' } }}
  it { is_expected.to run.with_params('file').and_return(result) }
  it { is_expected.to run.with_params('file', 'foo').and_return(result) }
  it { is_expected.to run.with_params('file', 'foo', {'foo' => 'foo'}).and_return(result) }
  it { is_expected.to run.with_params('file', nil, {}, true).and_return(result_merge) }
  it { is_expected.to run.with_params('file', 'foo', {}, true).and_return(result_merge) }
  it { is_expected.to run.with_params('file', 'foo', {'foo' => 'foo'}, true).and_return(result_merge) }
end
