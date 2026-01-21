import math

type Conversion* = object
  base, growth, exponent: float


proc newConversion*(base, growth, exponent: float): Conversion =
  Conversion(base: base, growth: growth, exponent: exponent)


proc calc*(conversion: Conversion, value: float): float =
  conversion.base + conversion.growth * pow(value, conversion.exponent)