Redis = require "redis"
Url = require "url"

module.exports = (robot) ->
  info = Url.parse process.env.REDISTOGO_URL or process.env.REDISCLOUD_URL or process.env.BOXEN_REDIS_URL or process.env.REDIS_URL or 'redis://localhost:6379', true
  subClient = Redis.createClient(info.port, info.hostname)
  pubClient = Redis.createClient(info.port, info.hostname)
  prefix = robot.name

  channelName = (direction, action) ->
    return "#{prefix}:#{direction}:#{action}"

  envelopeGenerator = (user, room) ->
    return {
      user: robot.brain.userForId(user),
      room: room,
      message: null
    }

  subClient.on "pmessage", (pattern, channel, json) ->
    try
      message = JSON.parse json
    catch
      robot.logger.error "Received message on #{channel} was not valid JSON"
      robot.logger.error json
      return
    
    func = channel.split(":")[2]
    if func of robot.adapter and typeof robot.adapter[func] == 'function'
      robot.adapter[func] envelopeGenerator(message.user, message.room), message.message
    else
      robot.logger.error "Received message with invalid operation on #{channel}"

  subClient.psubscribe "#{prefix}:out:*"

  pubGenerator = (channel) ->
    return (response) ->
      robot.logger.debug "Message published to #{channel}"
      message = response.message
      pubClient.publish channelName("in", channel), JSON.stringify({
         user: message.user.id,
         room: message.room,
         message: message.text
      })

  robot.hear /^/i, pubGenerator("hear")

  robot.respond /.*/i, pubGenerator("respond")

  robot.enter pubGenerator("enter")

  robot.leave pubGenerator("leave")

  robot.topic pubGenerator("topic")

  robot.catchAll pubGenerator("catchAll")
