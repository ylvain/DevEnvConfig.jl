```@meta
CurrentModule = DevEnvConfig
DocTestSetup = quote
    using DevEnvConfig
end
```

# DevEnvConfig

Documentation for [DevEnvConfig](https://github.com/ylvain/DevEnvConfig.jl).

```@index
```

## Early release for registration. Do not use.

## Conventions

We use `TypeName|∅` to denote the type `Union{TypeName, Nothing}`
```julia
const ∅ = Nothing
Base.:|(::Type{A},::Type{B}) where {A,B} = Union{A,B}
```

## Exported API

```@autodocs
Modules = [DevEnvConfig]
```
