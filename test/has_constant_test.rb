require 'helper'

class Model
  include HasConstant
end

class TestHasConstant < Test::Unit::TestCase
  should 'default accessor to singular of the constant name' do
    Model.has_constant :titles, ['Mr', 'Mrs']
    assert Model.new.respond_to?(:title)
    assert Model.new.respond_to?(:title=)
  end

  should 'raise an exception when a value is provided which is not in the list' do
    Model.has_constant :titles, ['Mr', 'Mrs']
    m = Model.new
    assert_raise ArgumentError do
      m.title = 'Ms'
    end
  end

  should 'be able to override accessor' do
    Model.send(:attr_accessor, :salutation)
    Model.has_constant :titles, ['Mr', 'Mrs'], :accessor => :salutation
    m = Model.new
    m.salutation = 'Mr'
    assert_equal 'Mr', m.salutation
  end

  should 'be able to use an array' do
    Model.has_constant :titles, ['Mr', 'Mrs']
    assert_equal ['Mr', 'Mrs'], Model.titles
  end

  should 'only use uniq values' do
    Model.has_constant :titles, ['Mr', 'Mrs', 'Mr', 'Mr']
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

  context '#field_is?' do
    setup do
      Model.has_constant :titles, ['Mr', 'Mrs', 'Ms']
      @m = Model.new
      @m.title = 'Mr'
    end

    should 'be true when the value is equal to the supplied one' do
      assert @m.title_is?('Mr')
    end

    should 'be false when the value is not equal to the supplied one' do
      assert !@m.title_is?('Mrs')
    end
  end

  context '#field_in?' do
    setup do
      Model.has_constant :titles, ['Mr', 'Mrs', 'Ms']
      @m = Model.new
      @m.title = 'Mr'
    end

    should 'be true when the field value is in the supplied set of values' do
      assert @m.title_in?(['Mr', 'Ms'])
    end

    should 'be false when the field value is not in the supplied set of values' do
      assert !@m.title_in?(['Mrs', 'Ms'])
    end
  end

  context '#field_is_not?' do
     setup do
      Model.has_constant :titles, ['Mr', 'Mrs', 'Ms']
      @m = Model.new
      @m.title = 'Mr'
    end

     should 'be true when the field value is not equal to the supplied one' do
       assert @m.title_is_not?('Mrs')
     end

     should 'be false when the field value is equal to the supplied one' do
       assert !@m.title_is_not?('Mr')
     end
  end

  context '#field_not_in?' do
    setup do
      Model.has_constant :titles, ['Mr', 'Mrs', 'Ms']
      @m = Model.new
      @m.title = 'Mr'
    end

    should 'be true when the field value is not in the supplied list' do
      assert @m.title_not_in?(['Mrs', 'Ms'])
    end

    should 'be false when the field value is in the supplied list' do
      assert !@m.title_not_in?(['Mr', 'Mrs'])
    end
  end
end
