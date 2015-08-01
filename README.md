# Synapse
Use Redis pub-sub to allow Hubot to incorporate scripts written in other
languages.

## Why?
Sometimes, you may not want to write your Hubot scripts in Coffeescript. Or
maybe, you want to have a simple way to communicate with your Hubot from a
remote machine. Maybe you want to give everyone in your office the ability
to quickly hack and iterate on their own scripts running on their own
desktops all the while your Hubot goes about its business blissfully unaware.

Whatever your use case, Synapse is for you.

## How?
Glad you asked. Synapse uses the pub/sub functionality of the same Redis
instance that you're likely running as your Hubot persistence layer.
Two for one! Everybody wins!

Synapse is actually incredibly simple, you could probably write
and test your own version in a few hours, but I'll save you some work. If you
find my work to be subpar, feel free to leave an issue or submit a pull
request. Thanks champ.

Here's the docs.

### Receiving Messages
Messages sent out to channels of the form: `<prefix>:in:<operation>`.

Here, the prefix is either the name of the Hubot instance, or specified after
the `/` in a Redis URL (ex: `redis://<host>:<port>[/<channel_prefix>]`).
This is largely the same logic that the `redis-brain.coffee` script uses. The 
operation field is whatever Hubot listener the channel is attached to.

The currently supported operations are:
* `hear`
* `respond`
* `enter`
* `leave`
* `topic`
* `catchAll`

Incoming messages will be JSON of the form:
```javascript
{
   "user": <message.user.id>,
   "room": <message.room>,
   "message": <message.text>
}
```

### Sending Messages
Messages can be sent to the Hubot on any channel of the form:
`<prefix>:out:<operation>`

Prefix follows the same rules as above. `<operation>` here represents whichever
function on the `Adapter` you wish to be called. If that function does not
exist, Hubot will log an error.

Outgoing messages are read from the channel as JSON. The expected form is
identical to the incoming form.

## That's it?

"What is my purpose?"

To pass messages.

![To pass butter.](http://i.imgur.com/IxC2SCj.gif)
