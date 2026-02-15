# Package

version       = "0.1.0"
author        = "kouyama"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]


# Dependencies

requires "nim >= 2.2.6"

requires "naylib >= 26.02.0"
requires "perlin >= 0.9.0"
requires "astar >= 0.6.0"
requires "arraymancer >= 0.7.33"
requires "zippy >= 0.10.18"
requires "nimhdf5 >= 0.6.3"