require 'json'

class Flash
  # find the flash cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @old_cookie = req.cookies['_rails_lite_app_flash'] ? JSON.parse(req.cookies['_rails_lite_app_flash']) : {}
    @new_cookie = {}
  end

  def [](key)
    if @new_cookie.has_key?(key)
      @new_cookie[key]
    else
      @old_cookie[key]
    end
  end

  def []=(key, val)
    @new_cookie[key] = val
    # @old_cookie[key] = val => can either do this or change the [] reader to read from both new and old
  end

  def now
    @old_cookie
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies

  def store_flash(res)
    res.set_cookie('_rails_lite_app_flash', {path: '/', value: @new_cookie.to_json})
  end
end
