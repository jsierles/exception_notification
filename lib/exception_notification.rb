require 'action_dispatch'
require 'exception_notification/notifier'

class ExceptionNotifier
  def self.default_ignore_exceptions
    [].tap do |exceptions|
      exceptions << ActiveRecord::RecordNotFound if defined? ActiveRecord
      exceptions << AbstractController::ActionNotFound if defined? AbstractController
      exceptions << ActionController::RoutingError if defined? ActionController
    end
  end

  def initialize(app, options = {})
    @app, @options = app, options
    @options[:ignore_exceptions] ||= self.class.default_ignore_exceptions
  end

  def call(env)
    @app.call(env)
  rescue Exception => exception
    options = (env['exception_notifier.options'] ||= {})
    options.reverse_merge!(@options)

    unless Array.wrap(options[:ignore_exceptions]).include?(exception.class)
      Notifier.deliver_exception_notification(env, exception)
    end

    raise exception
  end
end