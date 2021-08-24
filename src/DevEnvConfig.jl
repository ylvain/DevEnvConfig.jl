module DevEnvConfig

"""
    @enum ActionStatus Success Warning Error

Return type of configuration actions
"""
@enum ActionStatus Success Warning Error

# The path the "src" directory of the package
function devEnvConfig_src_path()
    dirname(pathof(DevEnvConfig))
end

include("tools/GitTools.jl")
include("pkg/PkgCreate.jl")

"""
    function newpkg(pkname::String;
        dir             :: String|∅ = nothing,
        docrepo         :: String|∅ = nothing,
        private         :: Bool     = false,
        useextjl        :: Bool|∅   = nothing,
        generalregistry :: Bool|∅   = nothing,
        license         :: String|∅ = nothing) -> ActionStatus

Create a new package. This will use your GitHub account to:
* setup documentation generation and deployment,
* setup unit testing and badge status,
* setup code coverage on CodeCov and badge statu

# Arguments

* `pkname`: the name of the new Julia Package
* `dir`: the directory is which to create the package, defaul to `JULIA_PKG_DEVDIR`
* `docrepo`: the name of a GitHub repo used to publish the documentation, default to the package repo.
* `private`: set to `true` is this package is hosted in a private GitHub repository
* `useextjl`: set to `true` if the GitHub repository is named `PackageName.jl`, default to `!private`
* `generalregistry`: set to `true` if this package will be registered in General, default to `!private`
* `license`: name of the LICENSE file, default to `MIT` for public package
"""
const newpkg = PkgCreate.create
export newpkg



end # module DevEnvConfig
