# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::resource::reduce' do
  let(:pre_condition) do
    "function puppetdb_query($pql) {
      [
        {
          'title' => 'foo',
          'parameters' => { 'content' => 'foo' }
        },
        {
          'title' => 'bar',
          'parameters' => { 'content' => 'bar' }
        },
        {
          'title' => 'foo',
          'parameters' => { 'content' => 'bar' }
        }
      ]
    }
    "
  end
  let(:result) {{'foo' => { 'content' => 'bar' }, 'bar' => { 'content' => 'bar' } }}
  it { is_expected.to run.with_params('file').and_return(result) }
  it { is_expected.to run.with_params('file').and_return(result) }
  it { is_expected.to run.with_params('file').and_return(result) }
  it { is_expected.to run.with_params('file', 'foo').and_return(result) }
  it { is_expected.to run.with_params('file', 'foo', {'foo' => 'foo'}).and_return(result) }
  it { is_expected.to run.with_params('file', 'foo', {'foo' => 'foo'}, false).and_return(result) }
  it { is_expected.to run.with_params('file', 'foo', {'foo' => 'foo'}, false, false).and_return(result) }
end
