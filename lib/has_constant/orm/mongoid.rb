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
          plural = (options[:accessor] || name.to_s)

          class_eval do
            unless fields.map(&:first).include?(singular.to_s)
              if options[:as] == :array
                field plural.to_sym, { :type => Array, :default => [] }.
                  merge(options)
              else
                if values.is_a?(Hash) || values.respond_to?(:call) &&
                  values.call.is_a?(Hash)
                  type = String
                else
                  type = Integer
                end
                field singular.to_sym, { :type => type }.merge(options)
              end
            end

            index singular.to_sym, :background => true if options[:index]

            named_scope :by_constant, lambda { |constant,value| { :where =>
              { constant.to_sym => eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }
          end

          # Define the setter method here
          if options[:as] == :array
            define_method("#{plural}=") do |value_set|
              indexes = value_set.map do |value|
                self.class.send(plural).index(value)
              end
              write_attribute plural, indexes
            end
          end

          define_method("#{singular}=") do |val|
            if val.instance_of?(String)
              if self.class.send(name).respond_to?(:key)
                index = self.class.send(name.to_s).key(val).to_s
              elsif self.class.send(name).respond_to?(:index)
                index = self.class.send(name.to_s).index(val)
                index = index.to_s if self.class.send(name.to_s).is_a?(Hash)
              end
              if index
                write_attribute singular.to_sym, index
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
          if options[:as] == :array
            define_method(plural) do
              attributes[plural].map { |val| self.class.send(plural)[val] }
            end
          end

          define_method(singular) do
            if attributes[singular]
              res = self.class.send(name.to_s)[attributes[singular].to_i] rescue nil
              res ||= self.class.send(name.to_s)[attributes[singular]]
              res ||= self.class.send(name.to_s)[attributes[singular].to_sym]
            end
          end

          (class << self; self; end).instance_eval do
            if options[:as] == :array
              define_method "#{plural}_include".to_sym do |value|
                if value.is_a?(String)
                  where(plural.to_sym => values.index(value))
                else
                  where(plural.to_sym => value.map { |v| send(plural).index(v) })
                end
              end
            else
              define_method "#{singular}_is".to_sym do |values|
                values = values.lines.to_a if values.respond_to?(:lines)
                where(singular.to_sym.in => values.map do |v|
                  options = self.send(name.to_sym)
                  if options.respond_to?(:key)
                    options.key(v)
                  else
                    options.index(v)
                  end
                end)
              end

              define_method "#{singular}_is_not".to_sym do |values|
                values = values.lines.to_a if values.respond_to?(:lines)
                where(singular.to_sym.nin => values.map { |v| self.send(name.to_sym).index(v) })
              end
            end
          end
        end
      end
    end
  end
end
