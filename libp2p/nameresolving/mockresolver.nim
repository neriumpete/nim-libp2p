# Nim-LibP2P
# Copyright (c) 2023-2024 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

{.push raises: [].}

import std/tables, chronos, chronicles

import nameresolver

export tables

logScope:
  topics = "libp2p mockresolver"

type MockResolver* = ref object of NameResolver
  txtResponses*: Table[string, seq[string]]
  # key: address, isipv6?
  ipResponses*: Table[(string, bool), seq[string]]

method resolveIp*(
    self: MockResolver, address: string, port: Port, domain: Domain = Domain.AF_UNSPEC
): Future[seq[TransportAddress]] {.
    async: (raises: [CancelledError, TransportAddressError])
.} =
  var res: seq[TransportAddress]

  if domain == Domain.AF_INET or domain == Domain.AF_UNSPEC:
    for resp in self.ipResponses.getOrDefault((address, false)):
      res.add(initTAddress(resp, port))

  if domain == Domain.AF_INET6 or domain == Domain.AF_UNSPEC:
    for resp in self.ipResponses.getOrDefault((address, true)):
      res.add(initTAddress(resp, port))

  res

method resolveTxt*(
    self: MockResolver, address: string
): Future[seq[string]] {.async: (raises: [CancelledError]).} =
  self.txtResponses.getOrDefault(address)

proc new*(T: typedesc[MockResolver]): T =
  T()
