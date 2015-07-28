Redis = require "redis"
Url = require "url"

module.exports = (robot) ->
  info = Url.parse process.env.REDISTOGO_URL or process.env.REDISCLOUD_URL or process.env.BOXEN_REDIS_URL or process.env.REDIS_URL or 'redis://localhost:6379', true
  subClient = Redis.createClient(info.port, info.hostname)
  pubClient = Redis.createClient(info.port, info.hostname)
  prefix = robot.name

  channelName = (direction, action) ->
    return "#{prefix}:#{direction}:#{action}"

  subClient.on "pmessage", (pattern, channel, json) ->
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

    func = channel.split(":")[2]
    response = new robot.Response robot, message, null
    if func of response and typeof response[func] == 'function'
      response[func] message.body
    else
      robot.logger.debug "Received message with invalid operation on #{channel}"

  subClient.psubscribe "#{prefix}:out:*"

  pubGenerator = (channel) ->
    return (response) ->
      robot.logger.debug "Message published to #{channel}"
      pubClient.publish channelName("in", channel), JSON.stringify(response.message)

  robot.hear /^/i, pubGenerator("hear")

  robot.respond /.*/i, pubGenerator("respond")

  robot.enter pubGenerator("enter")

  robot.leave pubGenerator("leave")

  robot.topic pubGenerator("topic")

  robot.catchAll pubGenerator("catchAll")
