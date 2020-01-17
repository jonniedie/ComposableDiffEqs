
nargin(func) = [method.nargs-1 for method in methods(func).ms]

# To treat lists and nonlists the same
struct List end
struct NonList end

islist(::Type{<:AbstractVector}) = List()
islist(::Type{<:Tuple}) = List()
islist(::Type{<:Number}) = NonList()
islist(::Type{<:Nothing}) = NonList()

aslist(x::T) where T = aslist(islist(T), x)
aslist(::List, x) = x
aslist(::NonList, x) = [x]
