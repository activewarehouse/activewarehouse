# Provides 1.1.6 compatibility
module ActiveRecord #:nodoc:
  module Calculations #:nodoc:
    module ClassMethods #:nodoc:
      protected
      def construct_count_options_from_legacy_args(*args)
        options     = {}
        column_name = :all

        # We need to handle
        #   count()
        #   count(options={})
        #   count(column_name=:all, options={})
        #   count(conditions=nil, joins=nil)      # deprecated
        if args.size > 2
          raise ArgumentError, "Unexpected parameters passed to count(options={}): #{args.inspect}"
        elsif args.size > 0
          if args[0].is_a?(Hash)
            options = args[0]
          elsif args[1].is_a?(Hash)
            column_name, options = args
          else
            # Deprecated count(conditions, joins=nil)
            ActiveSupport::Deprecation.warn(
              "You called count(#{args[0].inspect}, #{args[1].inspect}), which is a deprecated API call. " +
              "Instead you should use count(column_name, options). Passing the conditions and joins as " +
              "string parameters will be removed in Rails 2.0.", caller(2)
            )
            options.merge!(:conditions => args[0])
            options.merge!(:joins      => args[1]) if args[1]
          end
        end

        [column_name, options]
      end
    end
  end
end

class Module #:nodoc:
  def alias_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?
    alias_method "#{aliased_target}_without_#{feature}#{punctuation}", target
    alias_method target, "#{aliased_target}_with_#{feature}#{punctuation}"
  end
end