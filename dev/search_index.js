var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = DevEnvConfig\nDocTestSetup = quote\n    using DevEnvConfig\nend","category":"page"},{"location":"#DevEnvConfig","page":"Home","title":"DevEnvConfig","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pulic repo of DevEnvConfig.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"#Early-release-for-registration.-Do-not-use.","page":"Home","title":"Early release for registration. Do not use.","text":"","category":"section"},{"location":"#Conventions","page":"Home","title":"Conventions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"We use TypeName|∅ to denote the type Union{TypeName, Nothing}","category":"page"},{"location":"","page":"Home","title":"Home","text":"const ∅ = Nothing\nBase.:|(::Type{A},::Type{B}) where {A,B} = Union{A,B}","category":"page"},{"location":"#Exported-API","page":"Home","title":"Exported API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [DevEnvConfig]","category":"page"},{"location":"#DevEnvConfig.ActionStatus","page":"Home","title":"DevEnvConfig.ActionStatus","text":"@enum ActionStatus Success Warning Error\n\nReturn type of configuration actions\n\n\n\n\n\n","category":"type"},{"location":"#DevEnvConfig.newpkg","page":"Home","title":"DevEnvConfig.newpkg","text":"function newpkg(pkname::String;\n    private         :: Bool,\n    dir             :: String|∅ = nothing,\n    docrepo         :: String|∅ = nothing,\n    useextjl        :: Bool|∅   = nothing,\n    generalregistry :: Bool|∅   = nothing,\n    license         :: String|∅ = nothing) -> ActionStatus\n\nCreate a new package. This will use your GitHub account to:\n\nsetup documentation generation and deployment,\nsetup unit testing and badge status,\nsetup code coverage on CodeCov and badge statu\n\nThis template handles private package repo, with doc deployment in another (public) repo. Also provides guided setup for code coverage reporting for private repo.\n\nArguments\n\npkname: the name of the new Julia Package\nprivate: set to true is this package is hosted in a private GitHub repository\ndir: the directory is which to create the package, defaul to JULIA_PKG_DEVDIR\ndocrepo: the name of a GitHub repo used to publish the documentation, default to the package repo.\nuseextjl: set totrueif the GitHub repository is namedPackageName.jl, default to!private`\ngeneralregistry: set to true if this package will be registered in General, default to !private\nlicense: name of the LICENSE file, default to MIT for public package\n\n\n\n\n\n","category":"function"}]
}