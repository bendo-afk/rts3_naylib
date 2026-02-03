import math

type Conversion* = object
  base, growth, exponent: float32


proc newConversion*(base, growth, exponent: float32): Conversion =
  Conversion(base: base, growth: growth, exponent: exponent)


proc calc*(conversion: Conversion, value: float32): float32 =
  conversion.base + conversion.growth * pow(value, conversion.exponent)