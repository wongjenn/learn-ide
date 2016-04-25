{CompositeDisposable} = require 'atom'
Terminal = require './models/terminal'
SyncedFS = require './models/synced-fs'
TerminalView = require './views/terminal'
SyncedFSView = require './views/synced-fs'
{EventEmitter} = require 'events'
ipc = require 'ipc'
LearnUpdater = require './models/learn-updater'

module.exports =
  config:
    oauthToken:
      type: 'string'
      title: 'OAuth Token'
      description: 'Your learn.co oauth token'
      default: "Paste your learn.co oauth token here"

  termViewState: null
  fsViewState: null
  subscriptions: null

  activate: (state) ->
    @oauthToken = atom.config.get('integrated-learn-environment.oauthToken')
    openPath = atom.blobStore.get('learnOpenUrl', 'learn-open-url-key')
    atom.blobStore.delete('learnOpenUrl')
    atom.blobStore.save()

    @term = new Terminal("wss://ile.learn.co:4463?token=" + @oauthToken)
    @termView = new TerminalView(state, @term, openPath)

    @fs = new SyncedFS("wss://ile.learn.co:4464?token=" + @oauthToken, @term)
    @fsViewEmitter = new EventEmitter
    @fsView = new SyncedFSView(state, @fs, @fsViewEmitter)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggleTerminal': =>
      @termView.toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:reset': =>
      @term.term.write('\n\rReconnecting...\r')
      ipc.send 'reset-connection'
      ipc.send 'connection-state-request'
    @subscriptions.add atom.commands.add 'atom-workspace', 'application:update-ile': =>
      updater = new LearnUpdater
      updater.checkForUpdate()

    ipc.send 'register-for-notifications', @oauthToken

    ipc.on 'remote-log', (msg) ->
      console.log(msg)

    ipc.on 'new-notification', (data) ->
      notif = new Notification data.displayTitle,
        body: data.message

      notif.onclick = ->
        notif.close()

      console.log(data)

    @fsViewEmitter.on 'toggleTerminal', =>
      @termView.toggle()

    autoUpdater = new LearnUpdater(true)
    autoUpdater.checkForUpdate()

  deactivate: ->
    @termView = null
    @fsView = null
    @subscriptions.dispose()

    ipc.send 'deactivate-listener'

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @fsView, priority: 5000)

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @fsView.serialize()
