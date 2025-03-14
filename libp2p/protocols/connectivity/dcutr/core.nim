# Nim-LibP2P
# Copyright (c) 2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

{.push raises: [].}

import std/sequtils

import chronos
import stew/objects

import ../../../multiaddress, ../../../errors, ../../../stream/connection
import ../../../protobuf/minprotobuf

export multiaddress

const DcutrCodec* = "/libp2p/dcutr"

type
  MsgType* = enum
    Connect = 100
    Sync = 300

  DcutrMsg* = object
    msgType*: MsgType
    addrs*: seq[MultiAddress]

  DcutrError* = object of LPError

proc encode*(msg: DcutrMsg): ProtoBuffer =
  result = initProtoBuffer()
  result.write(1, msg.msgType.uint)
  for addr in msg.addrs:
    result.write(2, addr)
  result.finish()

proc decode*(_: typedesc[DcutrMsg], buf: seq[byte]): DcutrMsg {.raises: [DcutrError].} =
  var
    msgTypeOrd: uint32
    dcutrMsg: DcutrMsg
  var pb = initProtoBuffer(buf)
  var r1 = pb.getField(1, msgTypeOrd)
  let r2 = pb.getRepeatedField(2, dcutrMsg.addrs)
  if r1.isErr or r2.isErr or not checkedEnumAssign(dcutrMsg.msgType, msgTypeOrd):
    raise newException(DcutrError, "Received malformed message")
  return dcutrMsg

proc send*(
    conn: Connection, msgType: MsgType, addrs: seq[MultiAddress]
) {.async: (raises: [CancelledError, LPStreamError]).} =
  let pb = DcutrMsg(msgType: msgType, addrs: addrs).encode()
  await conn.writeLp(pb.buffer)

proc getHolePunchableAddrs*(
    addrs: seq[MultiAddress]
): seq[MultiAddress] {.raises: [LPError].} =
  var result = newSeq[MultiAddress]()
  for a in addrs:
    # This is necessary to also accept addrs like /ip4/198.51.100/tcp/1234/p2p/QmYyQSo1c1Ym7orWxLYvCrM2EmxFTANf8wXmmE7DWjhx5N
    if [TCP, mapAnd(TCP_DNS, P2PPattern), mapAnd(TCP_IP, P2PPattern)].anyIt(it.match(a)):
      result.add(a[0 .. 1].tryGet())
  return result
