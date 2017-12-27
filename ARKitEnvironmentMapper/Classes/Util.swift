
func logit(_ x: CGFloat) -> CGFloat {
  let p = clamp(x, between: 0.0, and: 1.0)
  let logit = log(p / (1 - p))
  return clamp(logit, between: -6.0, and: 6.0)
}

func normalize(value: CGFloat, between min: CGFloat, and max: CGFloat, withMid mid: CGFloat) -> CGFloat {
  var normalized: CGFloat
  if value < mid {
    normalized = 1 - (value - min) / (mid - min)
  } else {
    normalized = (mid - value) / (max - mid)
  }
  normalized = clamp(normalized, between: -0.99, and: 0.99)
  return logit(normalized)
}

func clamp(_ value: CGFloat, between low: CGFloat, and up: CGFloat) -> CGFloat {
  return max(min(value, up), low)
}
