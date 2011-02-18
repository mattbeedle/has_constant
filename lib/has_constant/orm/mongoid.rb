module HasConstant
  module Orm
    module Mongoid
      extend ActiveSupport::Concern

      included do
        class_eval do
          validate :validate_has_constant_attributes
        end
      end

      def validate_has_constant_attributes
        @has_constant_errors.each do |key, value|
          self.errors.add key, value
        end if @has_constant_errors
      end

      module ClassMethods
        def has_constant( name, values = lambda { I18n.t(name) }, options = {} )
          super(name, values, options)

          singular = (options[:accessor] || name.to_s.singularize).to_s

          class_eval do
            unless fields.map(&:first).include?(singular.to_s)
              field singular.to_sym, { :type => values.is_a?(Hash) ? String : Integer }.merge(options)
            end

            index singular.to_sym, :background => true if options[:index]

            named_scope :by_constant, lambda { |constant,value| { :where =>
              { constant.to_sym => eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }
          end

          define_method("#{singular}=") do |val|
            if val.instance_of?(String)
              if values.is_a?(Array) && index = self.class.send(name.to_s).index(val)
                write_attribute singular.to_sym, index
              elsif values.is_a?(Hash) && values.has_value?(val)
                write_attribute singular.to_sym, values.invert[val]
              elsif !val.blank?
                values = values.call if values.respond_to?(:call)
                @has_constant_errors ||= {}
                @has_constant_errors.merge!(singular.to_sym => "must be one of #{values.join(', ')}")
              end
            else
              write_attribute singular.to_sym, val
            end
          end

          # Add the getter method. This returns the string representation of the stored value
          define_method(singular) do
            if values.is_a?(Array)
              self.class.send(name.to_s)[attributes[singular].to_i] if attributes[singular]
            else
              self.class.send(name.to_s)[attributes[singular]] if attributes[singular]
            end
          end

          (class << self; self; end).instance_eval do
            define_method "#{singular}_is".to_sym do |values|
              values = values.lines.to_a if values.respond_to?(:lines)
              where(singular.to_sym => { '$in' => values.map { |v| self.send(name.to_sym).index(v) } })
            end

            define_method "#{singular}_is_not".to_sym do |values|
              values = values.lines.to_a if values.respond_to?(:lines)
              where(singular.to_sym => { '$nin' => values.map { |v| self.send(name.to_sym).index(v) } })
            end
          end
        end
      end
    end
  end
end
