localStorage = require './local-storage'

module.exports =
  isLastFocusedWindow: ->
    parseInt(localStorage.get('lastFocusedWindow')) == process.pid

  setLastFocusedWindow: ->
    localStorage.set('lastFocusedWindow', process.pid)

  trackFocusedWindow: ->
    @setLastFocusedWindow()
    window.onfocus = @setLastFocusedWindow

  spawn: (modulePath) ->
    {BufferedNodeProcess} = require 'atom'
    new BufferedNodeProcess({command: modulePath})

  cleanup: ->
    if @isLastFocusedWindow()
      localStorage.delete('lastFocusedWindow')

  emit: (key, detail) ->
    atom.emitter.emit(key, detail)

  on: (key, callback) ->
    atom.emitter.on(key, callback)

  closePaneItems: ->
    atom.workspace.getPanes().forEach (pane) ->
      pane.close()

