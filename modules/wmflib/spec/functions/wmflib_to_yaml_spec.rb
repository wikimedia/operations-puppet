# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
simple_data = {'key' => 'value'}
complex_data = {
  "hash" => {
    "int" => 42,
    "string" => "string",
    "boolean" => true,
    "array" => ["one", 2, [1, 2]],
    "array_hash" => [{"one" => "one", "two" => "two"}],
    "hash" => { "key" => "value", "array" => [1, 2, false]}
  }
}
simple_doc = <<-DOC
---
key: value
DOC
simple_doc_nohead = <<-DOC
key: value
DOC
complex_doc = <<-DOC
---
hash:
  int: 42
  string: string
  boolean: true
  array:
  - one
  - 2
  - - 1
    - 2
  array_hash:
  - one: one
    two: two
  hash:
    key: value
    array:
    - 1
    - 2
    - false
DOC

complex_doc_nohead = <<-DOC
hash:
  int: 42
  string: string
  boolean: true
  array:
  - one
  - 2
  - - 1
    - 2
  array_hash:
  - one: one
    two: two
  hash:
    key: value
    array:
    - 1
    - 2
    - false
DOC
describe 'wmflib::to_yaml' do
  it { is_expected.to run.with_params(simple_data).and_return(simple_doc_nohead) }
  it { is_expected.to run.with_params(simple_data, false).and_return(simple_doc) }
  it { is_expected.to run.with_params(complex_data).and_return(complex_doc_nohead) }
  it { is_expected.to run.with_params(complex_data, false).and_return(complex_doc) }
end
