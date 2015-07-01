# Example of async UDP handling
# Most of the code borrowed from asyncnet and adapted

import asyncdispatch, asyncnet, rawsockets, net, os
import unsigned
import strutils
from posix import setsockopt
from posix import inet_addr
from posix import InAddr
from posix import SockAddr


type 
  UDPPacket = tuple [data: string, peer: SockAddr_storage]

proc recvFrom*(socket: AsyncFD, size: int,
                 flags = {SocketFlag.SafeDisconn}): Future[UDPPacket] =
  var retFuture = newFuture[UDPPacket]("recv")

  var readBuffer= newString(size)
  var sockAddress: SockAddr_storage
  var addrLen = sizeof(sockAddress).SockLen

  proc cb(sock: AsyncFD): bool =
    var nullpkt: UDPPacket
    result = true
    let res = recvfrom(sock.SocketHandle, cstring(readBuffer), 
                 size.cint, 0, cast[ptr SockAddr](addr(sockAddress)), addr(addrLen))
    if res < 0:
      let lastError = osLastError()
      if lastError.int32 notin {EINTR, EWOULDBLOCK, EAGAIN}:
        if flags.isDisconnectionError(lastError):
          retFuture.complete(nullpkt)
        else:
          retFuture.fail(newException(OSError, osErrorMsg(lastError)))
      else:
        result = false # We still want this callback to be called.
    elif res == 0:
      # Disconnected
      retFuture.complete(nullpkt)
    else:
      var goodpkt: UDPPacket
      readBuffer.setLen(res)
      goodpkt.data = readBuffer
      goodpkt.peer = sockAddress
      retFuture.complete(goodpkt)
  # TODO: The following causes a massive slowdown.
  #if not cb(socket):
  addRead(socket, cb)
  return retFuture

proc sendTo(sk: AsyncSocket, peer: SockAddr_storage, data: string) =
  var sockAddress = peer
  var addrLen = sizeof(sockAddress).SockLen
  let res = posix.sendto(sk.getFd(), cast[pointer](cstring(data)), data.len, 0.cint, cast[ptr SockAddr](addr(sockAddress)), addrLen)


proc udpServe() {.async.} =
  var server = newAsyncSocket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP, false)
  server.bindAddr(Port(10000))
  while true:
    var (data, fromPeer) = await recvFrom(server.getFd().AsyncFD, 1500)
    sendTo(server,fromPeer, data)

asyncCheck udpServe()

runForever()
