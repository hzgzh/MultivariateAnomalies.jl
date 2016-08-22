using Distances


"""
    init_dist_matrix(data)

initialize a `D_out` object for `dist_matrix!()`.
"""

function init_dist_matrix{tp, N}(data::AbstractArray{tp, N})
  T = size(data, 1)
  dat = zeros(tp, T, size(data, N))
  tdat = zeros(tp, size(data, N), T)
  D = zeros(tp, T, T)
  D_out = (D, dat, tdat)
  return(D_out)
end

"""
    dist_matrix!

compute the distance matrix of `data`, similar to `dist_matrix()`. `D_out` object has to be preallocated, i.e. with `init_dist_matrix`.

```jldoctest
julia> dc = randn(10,4, 4,3)
julia> D_out = init_dist_matrix(dc)
julia> dist_matrix!(D_out, dc, lat = 2, lon = 2)
julia> D_out[1]
```
"""

function dist_matrix!{tp, N}(D_out::Tuple{Array{Float64,2},Array{Float64,2},Array{Float64,2}}, data::AbstractArray{tp, N}; dist::ASCIIString = "Euclidean", space::Int = 0, lat::Int = 0, lon::Int = 0, Q = 0)
  #@assert N == 2 || N == 3 || N  = 4
  (D, dat, tdat) = D_out
  if N == 2 copy!(dat, data) end
  if N == 3 copy!(dat, sub(data, :, space, :)) end
  if N == 4 copy!(dat, sub(data, :, lat, lon, :))  end
  transpose!(tdat, dat)
  if(dist == "Euclidean")         pairwise!(D, Euclidean(), tdat)
  elseif(dist == "SqEuclidean")   pairwise!(D, SqEuclidean(), tdat)
  elseif(dist == "Chebyshev")     pairwise!(D, Chebyshev(), tdat)
  elseif(dist == "Cityblock")     pairwise!(D, Cityblock(), tdat)
  elseif(dist == "JSDivergence")  pairwise!(D, JSDivergence(), tdat)
  elseif(dist == "Mahalanobis")   pairwise!(D, Mahalanobis(Q), tdat)
  elseif(dist == "SqMahalanobis") pairwise!(D, SqMahalanobis(Q), tdat)
  else print("$dist is not a defined distance metric, has to be one of 'Euclidean', 'SqEuclidean', 'Chebyshev', 'Cityblock' or 'JSDivergence'")
  end
  return(D_out[1])
end

"""
    dist_matrix{tp, N}(data::AbstractArray{tp, N}; dist::ASCIIString = "Euclidean", space::Int = 0, lat::Int = 0, lon::Int = 0, Q = 0)

compute the distance matrix of `data` i.e. the pairwise distances along the first dimension of data, using the last dimension as variables.
`dist` is a distance metric, currently `Euclidean`(default), `SqEuclidean`, `Chebyshev`, `Cityblock`, `JSDivergence`, `Mahalanobis` and `SqMahalanobis` are supported.
The latter two need a covariance matrix `Q` as input argument.

# Examples

```jldoctest
julia> dc = randn(10, 4,3)
julia> D = dist_matrix(dc, space = 2)
```
"""

function dist_matrix{tp, N}(data::AbstractArray{tp, N}; dist::ASCIIString = "Euclidean", space::Int = 0, lat::Int = 0, lon::Int = 0, Q = 0)
  D_out = init_dist_matrix(data)
  dist_matrix!(D_out, data, dist = dist, space = space, lat = lat, lon = lon ,Q = Q)
  return(D_out[1])
end

"""
    knn_dists(D, k::Int, temp_excl::Int = 5)

returns the k-nearest neighbors of a distance matrix `D`. Excludes `temp_excl` (default: `temp_excl = 5`) distances
from the main diagonal of `D` to be also nearest neighbors.

```jldoctest
julia> dc = randn(20, 4,3)
julia> D = dist_matrix(dc, space = 2)
julia> knn_dists_out = knn_dists(D, 3, 1)
julia> knn_dists_out[5] # distances
julia> knn_dists_out[4] # indices
```
"""

function knn_dists(D::AbstractArray, k::Int, temp_excl::Int = 5)
    T = size(D,1)
    if ((k + temp_excl) > T-1) print("k has to be smaller size(D,1)") end
    knn_dists_out = init_knn_dists(T, k)
    knn_dists!(knn_dists_out, D, temp_excl)
    return(knn_dists_out)
end

"""
    init_knn_dists(T::Int, k::Int)
    init_knn_dists(datacube::AbstractArray, k::Int)

initialize a preallocated `knn_dists_out` object. `k`is the number of nerarest neighbors, `T` the number of time steps (i.e. size of the first dimension) or a multidimensional `datacube`.
"""

function init_knn_dists(T::Int, k::Int)
    ix = zeros(Int64, T)
    v = zeros(Float64, T)
    indices = zeros(Int64, T, k)
    nndists = zeros(Float64, T, k)
    knn_dists_out = (k, ix, v, indices, nndists)
    return(knn_dists_out)
end

function init_knn_dists(datacube::AbstractArray, k::Int)
    T = size(datacube, 1)
    ix = zeros(Int64, T)
    v = zeros(Float64, T)
    indices = zeros(Int64, T, k)
    nndists = zeros(Float64, T, k)
    knn_dists_out = (k, ix, v, indices, nndists)
    return(knn_dists_out)
end

"""
    knn_dists!(knn_dists_out, D, temp_excl::Int = 5)

returns the k-nearest neighbors of a distance matrix `D`. Similar to `knn_dists()`, but uses preallocated input object `knn_dists_out`, initialized with `init_knn_dists()`.
Please note that the number of nearest neighbors `k` is not necessary, as it is already determined by the `knn_dists_out` object.

```jldoctest
julia> dc = randn(20, 4,3)
julia> D = dist_matrix(dc, space = 2)
julia> knn_dists_out = init_knn_dists(dc, 3)
julia> knn_dists!(knn_dists_out, D)
julia> knn_dists_out[5] # distances
julia> knn_dists_out[4] # indices
```
"""

function knn_dists!(knn_dists_out::Tuple{Int64,Array{Int64,1},Array{Float64,1},Array{Int64,2},Array{Float64,2}}, D::AbstractArray, temp_excl::Int = 5)
    (k, ix, v, indices, nndists) = knn_dists_out
    T = size(D,1)
    if ((k + temp_excl) > T-1) print("k has to be smaller size(D,1)") end
    maxD = maximum(D)
    for i = 1:T
        copy!(v, sub(D,:,i))
        for excl = -temp_excl:temp_excl
          if(i+excl > 0 && i+excl <= T)
            copy!(sub(v, i+excl), maxD)
          end
        end
        sortperm!(ix, v)
        for j = 1:k
            indices[i,j] = ix[j+1]
            nndists[i,j] = v[ix[j+1]]
        end
    end
    return(knn_dists_out)
end

"""
    kernel_matrix(D::AbstractArray, σ::Float64 = 1.0[, kernel::ASCIIString = "gauss", dimension::Int64 = 1])

compute a kernel matrix out of distance matrix `D`, given `σ`. Optionally normalized by the `dimension`, if `kernel = "normalized_gauss"`.

```jldoctest
julia> dc = randn(20, 4,3)
julia> D = dist_matrix(dc, space = 2)
julia> K = kernel_matrix(D, 2.0)
```
"""


# compute kernel matrix from distance matrix
function kernel_matrix(D::AbstractArray, σ::Float64 = 1.0, kernel::ASCIIString = "gauss", dimension::Int64 = 1)
    #if(size(D, 1) != size(D, 2)) print("D is not a distance matrix with equal dimensions")
    if(kernel == "normalized_gauss") # k integral gets one
        return(exp(-0.5 .* D/(σ^2))/((2*pi*σ*σ)^(dimension/2)))
    elseif (kernel == "gauss")
        return(exp(-0.5 .* D/(σ^2)))
    end
end

"""
    kernel_matrix!(K, D::AbstractArray, σ::Float64 = 1.0[, kernel::ASCIIString = "gauss", dimension::Int64 = 1])

compute a kernel matrix out of distance matrix `D`. Similar to `kernel_matrix()`, but with preallocated Array K (`K = similar(D)`) for output.

```jldoctest
julia> dc = randn(20, 4,3)
julia> D = dist_matrix(dc, space = 2)
julia> kernel_matrix!(D, D, 2.0) # overwrites distance matrix
```
"""

# compute kernel matrix from distance matrix
function kernel_matrix!{T,N}(K::AbstractArray{T,N}, D::AbstractArray{T,N}, σ::Real = 1.0, kernel::ASCIIString = "gauss", dimension::Int64 = 10)
    #if(size(D, 1) != size(D, 2)) print("D is not a distance matrix with equal dimensions")
    σ = convert(T, σ)
    if(kernel == "normalized_gauss") # k integral gets one
    for i in eachindex(K)
      @inbounds K[i] = exp(-0.5 .* D[i]./(σ.*σ))./((2 .*pi.*σ.*σ).^(dimension./2))
    end
    elseif (kernel == "gauss")
    for i in eachindex(K)
        @inbounds K[i] = exp(-0.5 .* D[i]./(σ.*σ))
    end
    end
  return(K)
end


###################################
#end
