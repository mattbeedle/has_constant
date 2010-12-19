module HasConstant
  module Orm
    module ActiveRecord
      extend ActiveSupport::Concern

      module ClassMethods
        def has_constant( name, values, options = {} )
          super(name, values, options)

          singular = (options[:accessor] || name.to_s.singularize).to_s

          # Add the getter method. This returns the string representation of the stored value
          define_method(singular) do
            self.class.send(name)[read_attribute(singular).to_i] if read_attribute(singular)
          end

          define_method("#{singular}=") do |val|
            if val.instance_of?(String)
              write_attribute singular.to_sym, self.class.send(name.to_s).index(val)
            else
              write_attribute singular.to_sym, val
            end
          end

          class_eval do
            named_scope :by_constant, lambda { |constant,value| { :conditions =>
              { constant.to_sym => eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }
            named_scope "#{singular}_is".to_sym, lambda { |*values| { :conditions =>
              { singular.to_sym => indexes_for(name, values) }
            } }
            named_scope "#{singular}_is_not".to_sym, lambda { |*values| { :conditions =>
              ["#{singular} NOT IN (?)", indexes_for(name, values)]
            } }
          end
        end

      private
        def indexes_for( name, values )
          values.map { |v| self.send(name.to_sym).index(v) }
        end
      end
    end
  end
end if defined?(ActiveRecord::Base)
