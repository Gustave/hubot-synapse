Redis = require "redis"
Url = require "url"

module.exports = (robot) ->
  info = Url.parse process.env.REDISTOGO_URL or process.env.REDISCLOUD_URL or process.env.BOXEN_REDIS_URL or process.env.REDIS_URL or 'redis://localhost:6379', true
  subClient = Redis.createClient(info.port, info.hostname)
  pubClient = Redis.createClient(info.port, info.hostname)
  prefix = robot.name

  channelName = (action) ->
    return "#{prefix}:#{action}"

  channelNames = (actions...) ->
    channels = []
    for action in actions
      channels.push channelName(action)
    return channels

  subClient.on "message", (channel, json) ->
    try
      message = JSON.parse json
    catch
      robot.logger.debug "Received invalid message on #{channel}"
      robot.logger.debug json
      return
    
    if not message.user? or not message.room? or not message.body?
      robot.logger.debug "Received invalid message on #{channel}"
      robot.logger.debug message
      return

    response = new robot.Response robot, message, null
    if channel == channelName("send")
      response.send message.body
    if channel == channelName("emote")
      response.emote message.body
    if channel == channelName("reply")
      response.reply message.body
    if channel == channelName("topic")
      response.topic message.body
    if channel == channelName("play")
      response.play message.body
    if channel == channelName("locked")
      response.locked message.body

  for channel in channelNames("send", "emote", "reply", "topic", "play", "locked")
   subClient.subscribe channel

  pubGenerator = (channel) ->
    return (response) ->
      robot.logger.debug "Message published to #{channel}"
      pubClient.publish channelName(channel), JSON.stringify(response.message)

  robot.hear /^/i, pubGenerator("hear")

  robot.respond /^/i, pubGenerator("respond")

  robot.enter pubGenerator("enter")

  robot.leave pubGenerator("leave")

  robot.topic pubGenerator("topic")

  robot.catchAll pubGenerator("catchAll")
