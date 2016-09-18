require 'erb'
require "byebug"

class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue Exception => e
      render_exception(e)
    end
  end

  private

  def render_exception(e)
    res = Rack::Response.new
    code_line = parse_source_code(e)
    content = File.read("lib/templates/rescue.html.erb")
    result = ERB.new(content).result(binding)
    res.status = 500
    res['Content-type'] = "text/html"
    res.write(result)
    res.finish
    # ["500", {'Content-type' => 'text/html'}, result]

# A preview of the source code where the exception was raised => get that from the e.backtrace (file and line #)
  end

  def parse_source_code(e)
    regex = Regexp.new '(?<file_name>.+\.rb):(?<l>\d+)'
    match_data = regex.match(e.backtrace[1])
    line = match_data[:l].to_i
    file_name = match_data[:file_name]
    code_line = File.readlines(file_name).map(&:chomp)[line-3..line+3]
    code_line
  end

end
