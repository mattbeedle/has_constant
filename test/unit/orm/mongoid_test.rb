require 'helper'
require 'mocha'

setup_mongoid

class MongoUser
  include Mongoid::Document
  include HasConstant

  has_constant :salutations, ['Mr', 'Mrs']
end if defined?(Mongoid)

class MongoUserWithProc
  include Mongoid::Document
  include HasConstant

  has_constant :salutations, lambda { ['Mr', 'Mrs'] }
end if defined?(Mongoid)

class MongoUserWithout
  include Mongoid::Document
  include HasConstant
end

class AnotherUser
  include Mongoid::Document
  include HasConstant
end

class Thing
  include Mongoid::Document
  include HasConstant
end

class MongoidTest < Test::Unit::TestCase
  context 'Instance' do
    context 'when storing arrays' do
      setup do
        MongoUserWithout.has_constant :sports, %w(running cycling tennis),
          :as => :array
        @user = MongoUserWithout.new :sports => %w(running tennis)
      end

      context 'setter' do
        should 'take an array' do
          assert_equal [0,2], @user.attributes['sports']
        end
      end

      context 'getter' do
        should 'return array of strings' do
          assert_equal %w(running tennis), @user.sports
        end
      end

      context 'named scopes' do
        setup do
          @u = MongoUserWithout.create! :sports => %w(running cycling)
          @u2 = MongoUserWithout.create! :sports => %w(running tennis)
        end

        context 'includes scope' do
          should 'return all where one of the array items is matched' do
            assert_equal 1, MongoUserWithout.sports_include('cycling').count
            assert MongoUserWithout.sports_include('cycling').include?(@u)
          end

          should 'work with array arguement' do
            result = MongoUserWithout.sports_include(%w(running tennis))
            assert_equal 1, result.count
            assert result.include?(@u2)
          end
        end
      end
    end

    context 'using a hash' do
      setup do
        Thing.has_constant :salutations, { :first => 'Mr', :second => 'Mrs' }
        @u = Thing.new :salutation => 'Mrs'
      end

      should 'store the hash key' do
        assert_equal 'second', @u.attributes['salutation']
      end

      should 'return the correct value' do
        assert_equal 'Mrs', @u.salutation
      end
    end

    should 'add the field automatically' do
      MongoUserWithout.has_constant :salutations, ['Mr', 'Mrs']
      assert MongoUserWithout.fields.map(&:first).include?('salutation')
    end

    should 'not add the field if it is already there' do
      MongoUserWithout.send(:field, :salutation, :type => Integer, :default => 0)
      MongoUserWithout.has_constant :salutations, ['Mr', 'Mrs']
      assert_equal 'Mr', MongoUserWithout.new.salutation
    end

    should 'be able to take default option' do
      AnotherUser.has_constant :salutations, lambda { %w(Mr Mrs) }, { :default => 0 }
      assert_equal 'Mr', AnotherUser.new.salutation
    end

    should 'take the accessor into account when adding the field' do
      MongoUserWithProc.has_constant :salutations, ['Mr', 'Mrs'], :accessor => :sal
      assert MongoUserWithProc.fields.map(&:first).include?('sal')
    end

    should 'default values to translated values list' do
      I18n.stubs(:t).returns(['a', 'b'])
      MongoUserWithout.has_constant :titles
      assert_equal ['a', 'b'], MongoUserWithout.titles
    end

    should 'add index when index option is supplied' do
      MongoUserWithout.has_constant :salutations, ['Mr', 'Mrs'], :index => true
      MongoUserWithout.create_indexes
      assert MongoUserWithout.index_information.keys.any? { |key| key.match(/salutation/) }
    end

    should 'not index when index option is not supplied' do
      MongoUser.create_indexes
      assert !MongoUser.index_information.keys.any? { |key| key.match(/salutation/) }
    end

    should 'save values as integers' do
      m = MongoUser.new(:salutation => 'Mr')
      m.save!
      assert_equal 'Mr', m.salutation
      assert_equal 0, m.attributes['salutation']
    end

    should 'not be valid when an incorrect value is supplied' do
      m = MongoUser.new(:salutation => 'asefe')
      assert !m.valid?
      assert_equal ['must be one of Mr, Mrs'], m.errors[:salutation]
    end

    should 'not be valid with an incorrect value is supplied and a proc/lambda has been used' do
      m = MongoUserWithProc.new(:salutation => 'asefe')
      assert !m.valid?
      assert_equal ['must be one of Mr, Mrs'], m.errors[:salutation]
    end

    should 'be valid when a blank value is supplied' do
      m = MongoUserWithProc.new(:salutation => '')
      assert m.valid?
    end
  end

  context 'Named Scopes' do
    setup do
      @man = MongoUser.create!(:salutation => 'Mr')
      @woman = MongoUser.create!(:salutation => 'Mrs')
    end

    should 'provide by_constant scope' do
      assert_equal 1, MongoUser.by_constant('salutation', 'Mr').count
      assert_equal @man, MongoUser.by_constant('salutation', 'Mr').first
    end

    should 'provide singular_is scope' do
      assert_equal 1, MongoUser.salutation_is('Mr').count
      assert_equal @man, MongoUser.salutation_is('Mr').first
    end

    should 'provide singular_is_not scope' do
      assert_equal 1, MongoUser.salutation_is_not('Mr').count
      assert_equal @woman, MongoUser.salutation_is_not('Mr').first
    end
  end
end if defined?(Mongoid)
