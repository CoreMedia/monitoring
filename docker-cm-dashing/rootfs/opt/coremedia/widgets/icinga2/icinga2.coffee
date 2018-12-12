class Dashing.Icinga2 extends Dashing.Widget
  @accessor 'current', Dashing.AnimatedValue

#   ready: ->
#     if @get('unordered')
#       $(@node).find('ol').remove()
#     else
#       $(@node).find('ul').remove()

  onData: (data) ->
#    console.log("Yeah! here is the icinga2 widget")
    if data.color
      # clear existing "color-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\bcolor-\S+/g, ''
      # add new class
      $(@get('node')).addClass "color-#{data.color}"

  checkUpdate: =>
    if updatedAt = @get('updatedAt')
      timestamp = new Date(updatedAt * 1000)
      now = new Date()
      diff = now.getTime() - timestamp.getTime()
      if diff > 30000
        @onData({color:'grey'})
