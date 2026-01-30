import raylib


proc getColRights*(texts: seq[seq[string]], fontSize: int32, padding: int32): seq[int32] =
  let length = texts[0].len
  var maxWidth: seq[int32]
  maxWidth.setLen(length)
  var colRight: seq[int32]
  colRight.setLen(length)
  
  for r in texts:
    for i, text in r:
      maxWidth[i] = max(maxWidth[i], measureText(text, fontSize))
  
  colRight[0] = maxWidth[0]
  for i in 1..colRight.high:
    colRight[i] = colRight[i - 1] + padding + maxWidth[i]
  
  return colRight