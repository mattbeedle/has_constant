require 'helper'
require 'mocha'

setup_mongoid

class MongoUser
  include Mongoid::Document
  include HasConstant
end if defined?(Mongoid)

class MongoUser2
  include Mongoid::Document
  include HasConstant
end if defined?(Mongoid)

class MongoUserWithHash
  include Mongoid::Document
  include HasConstant
end if defined?(Mongoid)

class MongoidTest < Test::Unit::TestCase
  context 'Instance' do

    context 'using a hash' do
      setup do
        MongoUserWithHash.has_constant :salutations, { :first => 'Mr', :second => 'Mrs' }
        @m = MongoUserWithHash.new(:salutation => 'Mr')
      end

      should 'store the hash key' do
        assert_equal 'first', @m.attributes['salutation']
      end

      should 'return the correct value' do
        assert_equal 'Mr', @m.salutation
      end
    end

    should 'add the field automatically' do
      MongoUser.has_constant :salutations, ['Mr', 'Mrs']
      assert MongoUser.fields.map(&:first).include?('salutation')
    end

    should 'not add the field if it is already there' do
      MongoUser.send(:field, :salutation, :type => Integer, :default => 0)
      MongoUser.has_constant :salutations, ['Mr', 'Mrs']
      assert_equal 'Mr', MongoUser.new.salutation
    end

    should 'be able to take default option' do
      MongoUser2.has_constant :salutations, lambda { %w(Mr Mrs) }, { :default => 0 }
      assert_equal 'Mr', MongoUser2.new.salutation
    end

    should 'take the accessor into account when adding the field' do
      MongoUser.has_constant :salutations, ['Mr', 'Mrs'], :accessor => :sal
      assert MongoUser.fields.map(&:first).include?('sal')
    end

    should 'default values to translated values list' do
      I18n.stubs(:t).returns(['a', 'b'])
      MongoUser.has_constant :titles
      assert_equal ['a', 'b'], MongoUser.titles
    end

    should 'add index when index option is supplied' do
      MongoUser.has_constant :salutations, ['Mr', 'Mrs'], :index => true
      MongoUser.create_indexes
      assert MongoUser.index_information.keys.any? { |key| key.match(/salutation/) }
    end

    should 'not index when index option is not supplied' do
      MongoUser2.create_indexes
      assert !MongoUser2.index_information.keys.any? { |key| key.match(/salutation/) }
    end

    should 'save values as integers' do
      MongoUser.has_constant :salutations, %w(Mr Mrs)
      m = MongoUser.new(:salutation => 'Mr')
      m.save!
      assert_equal 'Mr', m.salutation
      assert_equal 0, m.attributes['salutation']
    end

    should 'not be valid when an incorrect value is supplied' do
      MongoUser.has_constant :salutations, %w(Mr Mrs)
      m = MongoUser.new(:salutation => 'asefe')
      assert !m.valid?
      assert_equal ['must be one of Mr, Mrs'], m.errors[:salutation]
    end

    should 'not be valid with an incorrect value is supplied and a proc/lambda has been used' do
      MongoUser.has_constant :salutations, Proc.new { %w(Mr Mrs) }
      m = MongoUser.new(:salutation => 'asefe')
      assert !m.valid?
      assert_equal ['must be one of Mr, Mrs'], m.errors[:salutation]
    end

    should 'be valid when a blank value is supplied' do
      MongoUser.has_constant :salutations, Proc.new { %w(Mr Mrs) }
      m = MongoUser.new(:salutation => '')
      assert m.valid?
    end
  end

  context 'Named Scopes' do
    setup do
      MongoUser.has_constant :salutations, %w(Mr Mrs)
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
