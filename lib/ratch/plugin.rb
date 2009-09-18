module Ratch

  # = Plugin
  #
  # A Plugin is essentially a delegated Service class..
  #
  # The plugin acts a base class for ecapsulating batch routines.
  # This helps to keep the main batch context free of the clutter
  # of private supporting methods.
  #
  # Plugins are tightly coupled to the batch context,
  # which allows them to call on the context easily.
  # However this means plugins cannot be used independent
  # of a batch context, and changes in the batch context
  # can cause effects in plugin behvior that can be harder
  # to track down and fix if a bug arises.
  #
  # Unless the tight coupling of a plugin is required, use the
  # loose coupling of a Service class instead.
  #
  # The context must be a subclass of Ratch::DSL.
  #
  class Plugin

    # The batch context.
    attr :context

    private

    # Sets the context and assigns options to setter attributes
    # if they exist and values are not nil. That last point is
    # important. You must use 'false' to purposely negate an option.
    # +nil+ will instead allow any default setting to be used.
    def initialize(context, options=nil)
      @context = context

      raise TypeError, "context must be a subclass of Ratch::DSL" unless context.is_a?(Ratch::DSL)

      initialize_defaults

      options ||= {}
      options.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=") && !v.nil?
      end
    end

    # When subclassing, put default instance variable settngs here.
    # Eg.
    #
    #   def initialize_defaults
    #     @gravy = true
    #   end
    #
    def initialize_defaults
    end

    # TODO: Allow this to be optional? How?
    def method_missing(s, *a, &b)
      @context.send(s, *a, &b)
    end

  end

end
