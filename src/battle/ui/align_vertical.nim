import raylib


proc getColWidths*(texts: seq[seq[string]], fontSize: int32): seq[int32] =
  let colCount = texts[0].len
  result.setLen(colCount)
  
  for row in texts:
    for i, text in row:
      result[i] = max(result[i], measureText(text, fontSize))