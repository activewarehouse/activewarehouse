module ActiveWarehouse #:nodoc:
  module Builder #:nodoc:
    module Generator #:nodoc:
      # Generate a name consisting of one or more words from word groups
      class NameGenerator < ActiveWarehouse::Builder::Generator::Generator
        def next(options={})
          options[:separator] ||= ' '
          parts = []
          word_groups = options[:word_groups]
          0.upto(word_groups.first.length) do |i|
            word_groups.each do |word_group|
              parts << word_group[i]
            end
          end
          parts.join(options[:separator])
        end
      end
    end
  end
end