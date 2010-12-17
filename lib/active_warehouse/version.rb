module ActiveWarehouse #:nodoc:
  module VERSION #:nodoc:
    
    unless defined? STRING
      MAJOR = 0
      MINOR = 4
      TINY  = 0

      STRING = [MAJOR, MINOR, TINY].join('.')
    end

  end
end
