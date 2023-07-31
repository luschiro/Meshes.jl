# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    hasintersect(g₁, g₂)

Tells whether or not geometries `g₁` and `g₂` intersect.

## References

* Gilbert, E., Johnson, D., Keerthi, S. 1988. [A fast
  Procedure for Computing the Distance Between Complex
  Objects in Three-Dimensional Space]
  (https://ieeexplore.ieee.org/document/2083)

### Notes

* The fallback algorithm works with any geometry that has
  a well-defined [`supportfun`](@ref).
"""
function hasintersect end

hasintersect(g) = Base.Fix2(hasintersect, g)

hasintersect(p₁::Point, p₂::Point) = p₁ == p₂

hasintersect(s₁::Segment, s₂::Segment) = !isnothing(s₁ ∩ s₂)

hasintersect(b₁::Box, b₂::Box) = !isnothing(b₁ ∩ b₂)

hasintersect(p::Point, g::Geometry) = p ∈ g

hasintersect(g::Geometry, p::Point) = hasintersect(p, g)

hasintersect(c::Chain, s::Segment) = hasintersect(segments(c), [s])

hasintersect(s::Segment, c::Chain) = hasintersect(c, s)

hasintersect(c₁::Chain, c₂::Chain) = hasintersect(segments(c₁), segments(c₂))

hasintersect(c::Chain, g::Geometry) = any(∈(g), vertices(c)) || hasintersect(c, boundary(g))

hasintersect(g::Geometry, c::Chain) = hasintersect(c, g)

function hasintersect(g₁::Geometry{Dim,T}, g₂::Geometry{Dim,T}) where {Dim,T}
  # must have intersection of bounding boxes
  hasintersect(boundingbox(g₁), boundingbox(g₂)) || return false

  # handle non-convex geometries
  if !isconvex(g₁)
    d₁ = simplexify(g₁)
    return hasintersect(d₁, g₂)
  elseif !isconvex(g₂)
    d₂ = simplexify(g₂)
    return hasintersect(g₁, d₂)
  end

  # initial direction
  c₁, c₂ = centroid(g₁), centroid(g₂)
  d = c₁ ≈ c₂ ? rand(Vec{Dim,T}) : c₂ - c₁

  # first point in Minkowski difference
  P = minkowskipoint(g₁, g₂, d)

  # origin of coordinate system
  O = minkowskiorigin(Dim, T)

  # initialize simplex vertices
  points = [P]

  # move towards the origin
  d = O - P
  while true
    P = minkowskipoint(g₁, g₂, d)
    if (P - O) ⋅ d < zero(T)
      return false
    end
    push!(points, P)

    # line segment case
    if length(points) == 2
      B, A = points
      AB = B - A
      AO = O - A
      d = AB × AO × AB
    else # simplex case
      C, B, A = points
      AB = B - A
      AC = C - A
      AO = O - A
      ABᵀ = AC × AB × AB
      ACᵀ = AB × AC × AC
      if ABᵀ ⋅ AO > zero(T)
        popat!(points, 1) # pop C
        d = ABᵀ
      elseif ACᵀ ⋅ AO > zero(T)
        popat!(points, 2) # pop B
        d = ACᵀ
      else
        return true
      end
    end
  end
end

hasintersect(m::Multi, g::Geometry) = hasintersect(collect(m), [g])

hasintersect(g::Geometry, m::Multi) = hasintersect(m, g)

hasintersect(m₁::Multi, m₂::Multi) = hasintersect(collect(m₁), collect(m₂))

hasintersect(d::Domain, g::Geometry) = hasintersect(d, [g])

hasintersect(g::Geometry, d::Domain) = hasintersect(d, g)

# fallback with iterators of geometries
function hasintersect(geoms₁, geoms₂)
  for g₁ in geoms₁, g₂ in geoms₂
    hasintersect(g₁, g₂) && return true
  end
  return false
end

# -------------------------
# solve method ambiguities
# -------------------------

hasintersect(p::Point, c::Chain) = p ∈ c

hasintersect(c::Chain, p::Point) = hasintersect(p, c)

hasintersect(p::Point, m::Multi) = p ∈ m

hasintersect(m::Multi, p::Point) = hasintersect(p, m)

hasintersect(c::Chain, m::Multi) = hasintersect(segments(c), collect(m))

hasintersect(m::Multi, c::Chain) = hasintersect(c, m)

# ------------------
# utility functions
# ------------------

# support point in Minkowski difference
function minkowskipoint(g₁::Geometry{Dim,T}, g₂::Geometry{Dim,T}, d) where {Dim,T}
  n = Vec{Dim,T}(d[1:Dim])
  v = supportfun(g₁, n) - supportfun(g₂, -n)
  Point(ntuple(i -> i ≤ Dim ? v[i] : zero(T), max(Dim, 3)))
end

# origin of coordinate system
minkowskiorigin(Dim, T) = Point(ntuple(i -> zero(T), max(Dim, 3)))
