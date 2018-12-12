
require 'dashing'

configure do
  set :auth_token, '%AUTH_TOKEN%'
  set :raise_errors, true

  # we need this for running behind a proxy
  set :default_dashboard, '%PROXY_PATH%/%DASHBOARD%'
  set :assets_prefix,     '%PROXY_PATH%/assets'

  # allow iframes e.g. icingaweb2
  # https://github.com/Shopify/dashing/issues/199
  # thx Sandro Lang
  set :protection, :except => :frame_options

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

# run Rack::URLMap.new('%PROXY_PATH%' => Sinatra::Application)

run Sinatra::Application
