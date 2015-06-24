# a simple example from http://nim-lang.org/docs/asyncnet.html

import asyncnet, asyncdispatch

var clients {.threadvar.}: seq[AsyncSocket]

proc processClient(client: AsyncSocket) {.async.} =
  while true:
    let line = await client.recvLine()
    for c in clients:
      await c.send(line & "\c\L")

proc serve() {.async.} =
  clients = @[]
  var server = newAsyncSocket() #AF_INET6, SOCK_STREAM, IPPROTO_TCP, false)
  server.bindAddr(Port(12345))
  server.listen()
  while true:
    let client = await server.accept()
    clients.add client
    asyncCheck processClient(client)

asyncCheck serve()

runForever()


