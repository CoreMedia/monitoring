class Dashing.Clock extends Dashing.Widget

  ready: ->
    setInterval(@startTime, 1500)

  startTime: =>
    today = new Date()
    formatter = DateFormatter()

    h = today.getHours()
    m = today.getMinutes()
    s = today.getSeconds()
    m = @formatTime(m)
    s = @formatTime(s)
    @set('time', h + ":" + m )
    @set('date', formatter.normal(today))

  formatTime: (i) ->
    if i < 10 then "0" + i else i

  DateFormatter = ->
    weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    months   = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
    pad = (n) ->
      if n < 10
        "0" + n
      else
        n

    brief: (date) ->
      month = 1 + date.getMonth()
      "#{pad date.getDate()}. #{pad month}. #{date.getFullYear()}"

    normal: (date) ->
      month   = 1 + date.getMonth()
      weekday = weekdays[date.getDay()]
      "#{weekday}, #{pad date.getDate()}.#{pad month}.#{date.getFullYear()}"

    verbose: (date) ->
      weekday = weekdays[date.getDay()]
      month = months[date.getMonth()]
      day = date.getDate()
      year = date.getFullYear();
      "#{weekday}, #{day}.#{month}.#{year}"
