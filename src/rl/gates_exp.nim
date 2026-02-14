import arraymancer

type ExpGate*[TT] {.final.} = ref object of Gate[TT]
  x: Variable[TT]


proc exp_backward_ag[TT](self: Gate[TT], payload: Payload[TT]): SmallDiffs[TT] =
  let gradient = payload.variable.grad
  result = newDiffs[TT](1)
  result[0] = gradient *. payload.variable.value


proc exp_cache[TT](result: Variable[TT], x: Variable[TT]) =
  var gate: ExpGate[TT]
  new gate
  gate.x = x

  result.grad = zeros_like result.value
  result.requires_grad = true

  register_node(
    "Exp",
    gate,
    exp_backward_ag[TT],
    result,
    x
  )


proc exp*[TT](x: Variable[TT]): Variable[TT] =
  new result
  result.context = x.context
  result.value = x.value.exp

  if x.is_grad_needed:
    result.exp_cache(x)


when isMainModule:
  let ctx = newContext Tensor[float32]
  var x = ctx.variable([1'f32].toTensor, true)

  let xExp = x.exp
  backprop(xExp)
  echo xExp.value
  echo x.grad