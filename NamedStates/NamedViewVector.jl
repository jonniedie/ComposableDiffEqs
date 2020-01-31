include("MutableNamedTuples.jl")

import RecursiveArrayTools:
    recursive_unitless_eltype,
    recursive_bottom_eltype,
    recursive_unitless_bottom_eltype,
    recursivecopy

# Convenience closure for creating NamedTuple constructor
Struct(keys...) = (args...) -> (; zip(keys, args)...)
MutableStruct(keys...) = (args...) -> MutableNamedTuple((; zip(keys, args)...))

struct NamedViewVector{T} <: AbstractVector{T}
    data::MutableNamedTuple
    vector::Array{SubArray{T,0,Array{T,1},Tuple{Int64},true}, 1}
end
function NamedViewVector{T}(mnt::MutableNamedTuple) where {T}
    mnt = recursive_convert(T, mnt)
    return NamedViewVector{T}(mnt, attached_vect(mnt))
end
NamedViewVector{T}(nt::NamedTuple) where {T} = NamedViewVector{T}(MutableNamedTuple(nt))

function attached_vect(mnt::MutableNamedTuple)
    vector = []
    for (key, val) in zip(keys(mnt), values(mnt))
        if val[1] isa Number
            push!(vector, view(val, 1))
        elseif val[1] isa AbstractVector
            for i in eachindex(val[1])
                push!(vector, view(val[1], i))
            end
        elseif val[1] isa MutableNamedTuple
            push!(vector, attached_vect(val[1])...)
        end
    end
    return vector
end
attached_vect(mnt::MutableNamedTuple, ::Type{T}) where {T} =
    recursive_convert(T, mnt) |> attached_vect


recursive_convert(::Type{T}, num::Number) where {T} = T(num)
recursive_convert(::Type{T}, arr::AbstractArray) where {T} = recursive_convert.(T, arr)
function recursive_convert(::Type{T}, nt::NamedTuple) where {T}
    vals = []
    for (key, val) in zip(keys(nt), values(nt))
        push!(vals, key => recursive_convert(T, val))
    end
    return (; vals...)
end
recursive_convert(::Type{T}, mnt::MutableNamedTuple) where {T} =
    MutableNamedTuple(recursive_convert(T, namedtuple(mnt)))

Base.length(nvv::NamedViewVector) = length(getfield(nvv, :vector))

Base.size(nvv::NamedViewVector) = size(getfield(nvv, :vector))

Base.IndexStyle(nvv::NamedViewVector) = IndexLinear()

Base.getindex(nvv::NamedViewVector, i::Int) = getfield(nvv, :vector)[i][1][1]
# Base.getindex(nvv::NamedViewVector, I::Vararg{Int,N}) where {N} = getfield(nvv, :vector)[I...]
# Base.getindex(nvv::NamedViewVector, ::Colon) = getfield(nvv, :vector)[:]
Base.getindex(nvv::NamedViewVector, kr::AbstractRange) = getindex.(getfield(nvv, :vector)[kr], 1)
# Base.getindex(nvv::NamedViewVector, idx...) = getfield(nvv, :vector)[idx...]
Base.getindex(nvv::NamedViewVector, key::Symbol) = getfield(nvv, :data)[key]

function Base.setindex!(nvv::NamedViewVector, v, i::Int)
    getfield(nvv, :vector)[i][1] = v
    return nothing
end
# # Base.setindex!(nvv::NamedViewVector, v, I::Vararg{Int,N}) where {N} = (getfield(nvv, :vector)[I...] .= v)
function Base.setindex!(nvv::NamedViewVector, v, ::Colon)
    for i in eachindex(nvv)
        getfield(nvv, :vector)[i][1] = v
    end
    return nothing
end
function Base.setindex!(nvv::NamedViewVector, v, kr::AbstractRange)
    for i in kr
        getfield(nvv, :vector)[i][1] = v
    end
    return nothing
end
function Base.setindex!(nvv::NamedViewVector, v, key::Symbol)
    getfield(nvv, :data)[key] = v
    return nothing
end

# Base.copyto!(nvv::NamedViewVector, src::AbstractArray) = (nvv[1:length(src)] = src)
# Base.copyto!(nvv::NamedViewVector, src::Base.Broadcast.Broadcasted) = (nvv[1:length(src)] = src)
# function Base.copyto!(nvv::NamedViewVector, doff, src, soff, N)
#     rng = 0:N-1
#     nvv[doff .+ rng] = src[soff .+ rng]
#     return nvv
# end

Base.getproperty(nvv::NamedViewVector, key::Symbol) = getfield(nvv, :data)[key]

function Base.setproperty!(nvv::NamedViewVector, key::Symbol, val)
    setproperty!(getfield(nvv, :data), key, val)
    # setindex!(getfield(getfield(getfield(nvv, :data), :data), key), val, 1)
    return nothing
end

Base.propertynames(nvv::NamedViewVector) = propertynames(getfield(nvv, :data))

Base.similar(nvv::NamedViewVector{T}) where {T} = NamedViewVector{T}(namedtuple(getfield(nvv, :data)))
Base.similar(nvv::NamedViewVector,::Type{T}) where T = NamedViewVector{T}(getfield(nvv, :data))

# Yikes. FIXME.
viewvect_bottom_type(vector) = map(x->x[1][1], vector) |> eltype
recursive_unitless_bottom_eltype(nvv::NamedViewVector) = eltype(nvv)
recursive_bottom_eltype(nvv::NamedViewVector) = recursive_unitless_bottom_eltype(nvv)
recursive_unitless_eltype(nvv::NamedViewVector) = recursive_unitless_bottom_eltype(nvv)
recursivecopy(nvv::NamedViewVector) = deepcopy(nvv)

Base.abs2(sa::SubArray) = abs2.(sa)
Base.:/(sa1::SubArray, sa2::SubArray) = sa1 ./ sa2
Base.isnan(sa::SubArray) = isnan.(sa)

vector(nvv::NamedViewVector) = getfield(nvv, :vector)

# Base.:+(nvv1::NamedViewVector, nvv2::NamedViewVector) = vector(nvv1) + vector(nvv2)
# Base.:*(x::Number, nvv::NamedViewVector) = x * vector(nvv)

function Base.show(io::IO, nvv::NamedViewVector)
    show(io, getfield(nvv, :data))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", nvv::NamedViewVector)
    print(io, "NamedViewVector")
    show(io, getfield(nvv, :data))
    return nothing
end
