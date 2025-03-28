# Nim-LibP2P
# Copyright (c) 2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

{.push raises: [].}

import chronos
import secure, ../../stream/connection

const PlainTextCodec* = "/plaintext/1.0.0"

type PlainText* = ref object of Secure

method init(p: PlainText) {.gcsafe.} =
  proc handle(conn: Connection, proto: string) {.async: (raises: [CancelledError]).} =
    ## plain text doesn't do anything
    discard

  p.codec = PlainTextCodec
  p.handler = handle

proc new*(T: typedesc[PlainText]): T =
  let plainText = T()
  plainText.init()
  plainText
