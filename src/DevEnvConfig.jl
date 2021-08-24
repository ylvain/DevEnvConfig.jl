module DevEnvConfig

# The path the "src" directory of the package
function devEnvConfig_src_path()
    dirname(pathof(DevEnvConfig))
end

include("tools/GitTools.jl")
include("pkg/PkgCreate.jl")


const create = PkgCreate.create


end # module DevEnvConfig
