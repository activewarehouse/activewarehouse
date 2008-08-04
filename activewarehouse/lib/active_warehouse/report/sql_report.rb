module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    # A report which displays the SQL used to generate a tabular report.
    class SqlReport
      include AbstractReport
      
      # AbstractReport seems to assume it will be mixed into an
      # ActiveRecord::Base subclass -- it uses read_attribute (which
      # is one way of accessing model attributes), as well as using
      # attribute accessors that are defined when TableReport inherits
      # from ActiveRecord::Base.
      #    
      # To get around this, we put all the fields into the +params+ hash
      # that is passed into the intialization of the SqlReport.  Then
      # we define read_attribute and method_missing to access this
      # hash directly.
      # 
      # If you have a better solution - go for it!
      def initialize(params)
        @params = params
        # AbstractReport assumes html_params expects a hash, not nil
        @params[:html_params] ||= {}
      end

      def view(params, options = {})
        ActiveWarehouse::View::SqlView.new(self, params, options)
      end
      
      # Hack - see explanation for new (initialize).
      def conditions
        @params[:conditions]
      end
      
      protected
      
      # Hack - see explanation for new (initialize).
      def read_attribute(key)
        @params[key]
      end
      
      # Hack - see explanation for new (initialize).
      def method_missing(method, *args)
        @params[method.to_sym]
      end
    end
  end
end