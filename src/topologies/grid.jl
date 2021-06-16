using Base: StatusConnecting
# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    GridTopology(size)

A data structure for grid topologies of given `size`.
"""
struct GridTopology{D} <: Topology
  size::NTuple{D,Int}
end

GridTopology(size::Vararg{Int,D}) where {D} = GridTopology{D}(size)

"""
    size(t)

Return the size of the grid topology `t`, i.e. the
number of elements along each dimension of the grid.
"""
Base.size(t::GridTopology) = t.size

# ---------------------
# HIGH-LEVEL INTERFACE
# ---------------------

nvertices(t::GridTopology) = prod(t.size .+ 1)

function faces(t::GridTopology{D}, rank) where {D}
  if rank == D
    elements(t)
  elseif rank == D - 1
    facets(t)
  else
    throw(ErrorException("not implemented"))
  end
end

function element(t::GridTopology{D}, ind) where {D}
  l2c(ind) = CartesianIndices(t.size)[ind].I
  c2l(ind...) = LinearIndices(t.size .+ 1)[ind...]
  if D == 1
    i1 = ind
    i2 = ind+1
    connect((i1, i2), Segment)
  elseif D == 2
    i, j = l2c(ind)
    i1 = c2l(i  , j  )
    i2 = c2l(i+1, j  )
    i3 = c2l(i+1, j+1)
    i4 = c2l(i  , j+1)
    connect((i1, i2, i3, i4), Quadrangle)
  elseif D == 3
    i, j, k = l2c(ind)
    i1 = c2l(i  , j  , k  )
    i2 = c2l(i+1, j  , k  )
    i3 = c2l(i+1, j+1, k  )
    i4 = c2l(i  , j+1, k  )
    i5 = c2l(i  , j  , k+1)
    i6 = c2l(i+1, j  , k+1)
    i7 = c2l(i+1, j+1, k+1)
    i8 = c2l(i  , j+1, k+1)
    connect((i1, i2, i3, i4, i5, i6, i7, i8), Hexahedron)
  else
    throw(ErrorException("not implemented"))
  end
end

nelements(t::GridTopology) = prod(t.size)

function facet(t::GridTopology{D}, ind) where {D}
  if D == 1
    ind
  elseif D == 2
    throw(ErrorException("not implemented"))
  elseif D == 3
    throw(ErrorException("not implemented"))
  else
    throw(ErrorException("not implemented"))
  end
end

function nfacets(t::GridTopology{D}) where {D}
  if D == 1
    t.size[1] + 1
  elseif D == 2
    2prod(t.size) +
    t.size[1] +
    t.size[2]
  elseif D == 3
    3prod(t.size) +
    prod(t.size[[1,2]]) +
    prod(t.size[[1,3]]) +
    prod(t.size[[2,3]])
  else
    throw(ErrorException("not implemented"))
  end
end
