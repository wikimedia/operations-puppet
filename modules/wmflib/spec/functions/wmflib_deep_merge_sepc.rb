require_relative '../../../../rake_modules/spec_helper'

hash1 = {'a' => [1]}
hash2 = {'a' => [2]}

describe 'wmflib::deep_merge' do
  it { is_expected.to run.with_params(hash1, hash2).and_return({'a' => [2, 1]}) }

  describe 'stdlib deep merge checks' do
    describe 'when arguments have key collisions' do
      it 'prefers values from the last hash' do
        is_expected.to run \
          .with_params({ 'key1' => 'value1', 'key2' => 'value2' }, 'key2' => 'replacement_value', 'key3' => 'value3') \
          .and_return('key1' => 'value1', 'key2' => 'replacement_value', 'key3' => 'value3')
      end
    end

    describe 'when arguments have subhashes' do
      it {
        is_expected.to run \
        .with_params({ 'key1' => 'value1' }, 'key2' => 'value2', 'key3' => { 'subkey1' => 'value4' }) \
        .and_return('key1' => 'value1', 'key2' => 'value2', 'key3' => { 'subkey1' => 'value4' })
      }
      it {
        is_expected.to run \
        .with_params({ 'key1' => { 'subkey1' => 'value1' } }, 'key1' => { 'subkey2' => 'value2' }) \
        .and_return('key1' => { 'subkey1' => 'value1', 'subkey2' => 'value2' })
      }
      it {
        is_expected.to run \
        .with_params({ 'key1' => { 'subkey1' => { 'subsubkey1' => 'value1' } } }, 'key1' => { 'subkey1' => { 'subsubkey1' => 'value2' } }) \
        .and_return('key1' => { 'subkey1' => { 'subsubkey1' => 'value2' } })
      }
    end

    arguments = { 'key1' => 'value1' }, { 'key2' => 'value2' }
    originals = [arguments[0].dup, arguments[1].dup]
    it 'does not change the original hashes' do
      subject.execute(arguments[0], arguments[1])
      arguments.each_with_index do |argument, index|
        expect(argument).to eq(originals[index])
      end
    end

    context 'with UTF8 and double byte characters' do
      it { is_expected.to run.with_params({ 'ĸέỹ1' => 'ϋǻļủë1' }, 'この文字列' => '万').and_return('ĸέỹ1' => 'ϋǻļủë1', 'この文字列' => '万') }
    end
  end
end
