module HasConstant

  def self.included(base)
    base.extend(ClassMethods)
  end

  # HasConstant takes a Proc containing an array of possible values for a field name
  # The field name is inferred as the singular of the has constant name. For example
  # has_constant :titles
  # would use the database column "title"
  #
  # USAGE:
  #
  # class User < ActiveRecord::Base
  #   include HasConstant
  #   has_constant :titles, lambda { %w(Mr Mrs) }
  # end
  #
  # User.titles #=> ['Mr', 'Ms']
  #
  # @user = User.new(:title => 'Mr')
  # @user.title #=> 'Mr'
  # @user.attributes['title'] #=> 0
  #
  # @user.title_is?('Mr') #=> true
  # @user.title_is?('Ms') #=> false
  #
  # User.by_constant('title', 'Mr') #=> [@user]
  #
  module ClassMethods

    def has_constant(name, values, options = {})

      singular = (options[:column_name] || name.to_s.singularize).to_s

      (class << self; self; end).instance_eval do
        define_method(name.to_s, values) if values.respond_to?(:call)
        define_method(name.to_s, lambda { values }) unless values.respond_to?(:call)
      end

      self.class_eval do
        if respond_to?(:named_scope)
          named_scope :by_constant, lambda { |constant,value| { :where =>
            { constant.to_sym => eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }
          named_scope "#{singular}_is".to_sym, lambda { |*values| { :where =>
            { singular.to_sym => { '$in' =>  values.map { |v| self.send(name.to_sym).index(v) } } } } }
          named_scope "#{singular}_is_not".to_sym, lambda { |*values| { :where =>
            { singular.to_sym => { '$nin' => values.map { |v| self.send(name.to_sym).index(v) } } } } }
        end
      end

      # Add the getter method. This returns the string representation of the stored value
      define_method("#{singular}") do
        eval("#{self.class}.#{name.to_s}[self.attributes[singular].to_i] if self.attributes[singular]")
      end

      # Add the setter method. This takes the string representation and converts it to an integer to store in the DB
      define_method("#{singular}=") do |val|
        if val.instance_of?(String)
          eval("write_attribute(:#{singular}, #{self.class}.#{name.to_s}.index(\"#{val}\"))")
        else
          write_attribute singular.to_sym, val
        end
      end

      define_method("#{name.to_s.singularize}_is?") do |value|
        eval("#{singular} == '#{value.to_s}'")
      end
    end
  end
end
