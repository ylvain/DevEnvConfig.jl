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
function devEnvConfig_pkg_path()
    dirname(devEnvConfig_src_path())
end

include("tools/RuntimeEnv.jl")
include("tools/RuntimeContext.jl")
include("tools/CmdTools.jl")
include("tools/GitTools.jl")
include("sysimages/SysImageBuilder.jl")
include("pkg/PkgCreate.jl")

"""
    function newpkg(pkname::String;
        private         :: Bool,
        dir             :: String|∅ = nothing,
        docrepo         :: String|∅ = nothing,
        useextjl        :: Bool|∅   = nothing,
        generalregistry :: Bool|∅   = nothing,
        license         :: String|∅ = nothing) -> ActionStatus

Create a new package. This will use your GitHub account to:
* setup documentation generation and deployment,
* setup unit testing and badge status,
* setup code coverage on CodeCov and badge statu

This template handles private package repo, with doc deployment in another (public) repo.
Also provides guided setup for code coverage reporting for private repo.

# Arguments

* `pkname`: the name of the new Julia Package
* `private`: set to `true` is this package is hosted in a private GitHub repository
* `dir`: the directory is which to create the package, defaul to `JULIA_PKG_DEVDIR`
* `docrepo`: the name of a GitHub repo used to publish the documentation, default to the package repo.
* `useextjl`: set t`o `true` if the GitHub repository is named `PackageName.jl`, default to `!private`
* `generalregistry`: set to `true` if this package will be registered in General, default to `!private`
* `license`: name of the LICENSE file, default to `MIT` for public package
"""
const newpkg = PkgCreate.create
export newpkg

end # module DevEnvConfig
