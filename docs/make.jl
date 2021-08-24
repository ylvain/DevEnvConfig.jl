using DevEnvConfig
using Documenter

DocMeta.setdocmeta!(DevEnvConfig, :DocTestSetup, :(using DevEnvConfig); recursive=true)

# Note: even if this package is configured to use a GitHub repo name
# of the form PACKAGE (and *not* PACKAGE.jl), we still define the
# sitename to be PACKAGE.jl in the template below.
# Its recommended to keep this convention as this is what users may
# google for... (likewise for the title of the main README.md)

makedocs(;
    modules=[DevEnvConfig],
    authors="ylvain <ylvain.dev@ethics-gradient.org> and contributors",
    repo="https://github.com/ylvain/DevEnvConfig.jl/blob/{commit}{path}#{line}",
    sitename="DevEnvConfig.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ylvain.github.io/DevEnvConfig.jl/stable",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

let
    DEPLY_REPO = "ylvain/DevEnvConfig.jl" # we may deploy to another repo
    EVENT_NAME = get(ENV,"GITHUB_EVENT_NAME", "")
    if EVENT_NAME == "workflow_dispatch" || EVENT_NAME == "release"
        EVENT_NAME = "push" # allows deploy on manual invokation
    end
    withenv("GITHUB_REPOSITORY" => DEPLY_REPO, "GITHUB_EVENT_NAME" => EVENT_NAME) do
        deploydocs(;
            repo="github.com/"*DEPLY_REPO, # default is "github.com/ylvain/Pk1.jl"
            devurl="dev",         # default, subdir for push without tag
            forcepush=true,       # default:false, changes will be combined with the previous commit and force pushed, erasing the Git history on the deployment branch.
            devbranch="main",     # which branch to access for the doc build and content
            branch="gh-pages",        # on which branch of the deploy-repo do we commit the generated doc
        )
    end
end
