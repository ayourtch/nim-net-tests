# a simple example from http://nim-lang.org/docs/asyncnet.html

import asyncnet, asyncdispatch, rawsockets

var clients {.threadvar.}: seq[AsyncSocket]

proc processClient(client: AsyncSocket) {.async.} =
  while true:
    let line = await client.recvLine()
    for c in clients:
      await c.send(line & "\c\L")

proc serve() {.async.} =
  clients = @[]
  var server = newAsyncSocket() # AF_INET, SOCK_STREAM, IPPROTO_TCP, true)
  server.bindAddr(Port(12345))
  server.listen()
  while true:
    echo("Local socket port: ", $getSockName(server.getFd()))
    let (remoteAddr, client) = await server.acceptAddr()
    echo("Connection from ", remoteAddr)
    clients.add client
    asyncCheck processClient(client)

asyncCheck serve()

runForever()


