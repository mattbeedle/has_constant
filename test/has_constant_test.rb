require 'helper'

class Model
  include HasConstant

  attr_accessor :salutation
end

class TestHasConstant < Test::Unit::TestCase
  should 'default accessor to singular of the constant name' do
    Model.has_constant :titles, ['Mr', 'Mrs']
    assert Model.new.respond_to?(:title)
    assert Model.new.respond_to?(:title=)
  end

  should 'be able to override accessor' do
    Model.has_constant :titles, ['Mr', 'Mrs'], :accessor => :salutation
    m = Model.new
    m.salutation = 'Mr'
    assert_equal 'Mr', m.salutation
  end

  should 'be able to use an array' do
    Model.has_constant :titles, ['Mr', 'Mrs']
    assert_equal ['Mr', 'Mrs'], Model.titles
  end

  should 'be able to use a proc' do
    Model.has_constant :titles, Proc.new { ['Mr', 'Mrs'] }
    assert_equal ['Mr', 'Mrs'], Model.titles
  end

  should 'be able to use lambda' do
    Model.has_constant :titles, lambda { ['Mr', 'Mrs'] }
    assert_equal ['Mr', 'Mrs'], Model.titles
  end

  should 'provide singular_is? comparison method' do
    Model.has_constant :titles, ['Mr', 'Mrs']
    m = Model.new
    m.title = 'Mr'
    assert m.title_is?('Mr')
  end
end
