require 'spec_helper'

describe 'configparser_format' do
  it 'should format hash into ini format' do
    run.with_params({:section => {:param1 => 'value1', :param2 => 'value2'}})
                          .and_return(
                              "[section]\n"\
                              "param1 = value1\n"\
                              "param2 = value2\n"
                          )
  end

  it 'should sort parameters alphabetically' do
    run.with_params({:section => {:param2 => 'value2', :param1 => 'value1'}})
        .and_return(
            "[section]\n"\
            "param1 = value1\n"\
            "param2 = value2\n"
        )
  end

  it 'should format multiple hashes' do
    run.with_params({:section1 => {:param1 => 'value1'}}, {:section2 => {:param2 => 'value2'}})
        .and_return(
            "[section1]\n"\
            "param1 = value1\n"\
            "[section2]\n"\
            "param2 = value2\n"
        )
  end

  it 'should format array parameters' do
    run.with_params({:section1 => {:param1 => %w(item1 item2)}})
        .and_return(
            "[section1]\n"\
            "param1 = item1,item2\n"\
        )
  end
end
