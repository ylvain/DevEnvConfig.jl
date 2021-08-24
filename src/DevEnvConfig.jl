module DevEnvConfig

# Write your package code here.
# When you delete the example code below, you must also delete:
# - the test examples in test/runtests.jl
# - the docs example  in docs/src/index.md

export add, sub

"""
    add(x,y)

A wonderful way to call the Base.:+ function!

# Example
```jldoctest
julia> add(9.0, 3.0)
12.0
```
"""
function add(x,y)
    return x + y
end

"""
    sub(x::Int,y::Int) -> Int

A wonderful way to call the Base.:- function!

!!! note
    But only for type `Int`...

# Example
```jldoctest
julia> sub(9, 3)
6
```
"""
function sub(x::Int,y::Int)
    return x - y
end

end # module DevEnvConfig
