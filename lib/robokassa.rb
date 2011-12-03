module Robokassa
  mattr_accessor :interface_class

  # this allow use custom class for handeling api responces
  # === Example
  #   Robokassa.interface_class = MyCustomInterface
  #   Robokassa.interface_class.new(options)
  def self.interface_class
    @@interface_class || ::Robokassa::Interface
  end

  class Engine < Rails::Engine #:nodoc:
    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
    end

    config.to_prepare &method(:activate).to_proc
  end
end
