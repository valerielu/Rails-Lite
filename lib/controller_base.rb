  require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, option = {})
    @req = req
    @res = res
    @already_built_response = false
    @params = req.params.merge(option)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Double response" if already_built_response?
    @res['Location'] = url
    @res.status = 302
    @already_built_response = true
    session.store_session(@res)
    flash.store_flash(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Double response" if already_built_response?
    @res['Content-Type'] = content_type
    @res.write(content)
    @already_built_response = true
    session.store_session(@res)
    flash.store_flash(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    content = File.read("views/#{self.class.to_s.underscore}/#{template_name}.html.erb")
    result = ERB.new(content).result(binding)
    render_content(result, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  def form_authenticity_token
    @csrf_token ||= SecureRandom::urlsafe_base64(32)
    res.set_cookie('authenticity_token', {path: '/', value: @csrf_token})
    @csrf_token
  end

  def check_authenticity_token
    raise "Invalid authenticity token" unless params["authenticity_token"] == @req.cookies["authenticity_token"] && params["authenticity_token"]
  end

  def self.protect_from_forgery
    @@protection = true #viaraible under class method becomes a class variable
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(action_name)
    if @req.request_method != "GET" && @@protection
      check_authenticity_token
    end
    self.send(action_name)
    unless already_built_response?
      render(action_name)
    end
  end
end
