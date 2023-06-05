## This module implements a CUI operator for DB.
##

import options
import sequtils
import strformat
import tables

import docopt
import nazopuyo_core
import tiny_sqlite

import ./util
import ../core/db

proc operateDb*(args: Table[string, Value]) {.inline.} =
  ## Runs a CUI operator for DB.
  let db = connectDb()
  if db.isNone:
    echo "データベースファイルが開けません．"
    return
  defer: db.get.close

  if args["add"] or args["a"]:
    let urls = @(args["<urls>"]).deduplicate true
    for (url, nazo) in zip(urls, urls.mapIt it.toNazo true):
      if nazo.isNone:
        echo &"正しくない形式のURLです：{url}"
        continue

      if not db.get.insert nazo.get:
        echo &"既にデータベースに登録されています：{url}"
  elif args["remove"] or args["r"]:
    for url in @(args["<urls>"]):
      if not db.get.delete url:
        echo &"データベースに登録されていません：{url}"
  elif args["find"] or args["f"]:
    var saturates = newSeqOfCap[bool](2)
    if args["--fs"]:
      saturates.add true
    if args["--fS"]:
      saturates.add false

    var idx = 1
    for url in db.get.search(
      args["--fk"].mapIt it.parseRequirementKind,
      args["--fm"].mapIt it.parseNatural.Positive,
      saturates,
    ):
      echo &"({idx}) {url}"
      idx.inc
  else:
    raise newException(ValueError, "Impossible path.")