module Monitoring

  module Configure


  # -- CONFIGURE ------------------------------------------------------------------------
  #
#   def writeHostConfiguration( host, payload )
#
#     status       = 500
#     message      = 'initialize error'
#
#     current = Hash.new()
#     hash    = Hash.new()
#
#     if( host.to_s != '' )
#
# #       directory = self.createCacheDirectory( host )
#
#       hash = JSON.parse( payload )
#
#       hostInfo = Utils::Network.resolv( host )
#       host     = hostInfo.dig(:short)
#
#       @redis.create_config( { :short => host , :data => hash } )
#
#       status  = 200
#       message = 'config successful written'
#
#     end
#
#     return JSON.pretty_generate( {
#       :status  => status,
#       :message => message
#     } )
#
#   end
#
#
#   def getHostConfiguration( host )
#
#     if( host.to_s != '' )
#
#       hostInfo = Utils::Network.resolv( host )
#       host     = hostInfo.dig(:short)
#
#       data     = @redis.config( { :short => host } )
#
#       # logger.debug( data )
#
#       if( data != false )
#
#        return {
#           :status  => 200,
#           :message => data
#         }
#       end
#
#     end
#
#     return {
#       :status  => 204,
#       :message => 'no configuration found'
#     }
#
#   end
#
#
#   def removeHostConfiguration( host )
#
#     status       = 500
#     message      = 'initialize error'
#
#
#     if( host.to_s != '' )
#
#       hostInfo = Utils::Network.resolv( host )
#       host     = hostInfo.dig(:short)
#
#       data     = @redis.remove_config( { :short => host } )
#
#       if( data != false )
#         status = 200
#         message = 'configuration succesfull removed'
#       else
#         status  = 404
#         message = 'No configuration found'
#       end
#     end
#
#     return JSON.pretty_generate( {
#       :status  => status,
#       :message => message
#     } )
#
#   end
#
  end
end
