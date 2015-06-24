# a simple example from http://nim-lang.org/docs/asyncnet.html

import asyncnet, asyncdispatch, rawsockets

proc serve() {.async.} =
  var client = newAsyncSocket() # AF_INET, SOCK_STREAM, IPPROTO_TCP, true)
  await client.connect("127.0.0.1", Port(12345))

asyncCheck serve()

runForever()


