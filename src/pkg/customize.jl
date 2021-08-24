
# ==================================================================================
#                Custom Templates
# ==================================================================================

# Template: Tests.yml
# This is the template templates\github\workflows\CI.yml of PkgTemplates v0.7.18 with,
# - Remove the job "docs" that build/deploy the doc for Documenter.jl
# - Changed the triggers, we keept the condition [push, pull_request], but only on branch "main"

# Template: CompatHelper.yml
# This is the template templates\github\workflows\CompatHelper.yml of PkgTemplates v0.7.18 with,
# - Remove the authentication line in env: COMPATHELPER_PRIV: ${{ secrets.DOCUMENTER_KEY }}-
#   If the package deploy doc to another repo, it will be a DOCUMENTER_KEY. If a COMPATHELPER_PRIV
#   is present with a non-empty key, then CompatHelper will use it to deploy in preference to
#   the GITHUB_TOKEN. However, the DOCUMENTER_KEY may NOT give access to the repo itself but
#   only to the repo to which the doc is deployed.

# Template: README.md
# This is the template templates\README.md of PkgTemplates v0.7.18 with,
# - Very verbose extension...

# Template: docs_make.jlt
# This is the template templates\docs\make.jl of PkgTemplates v0.7.18 with,
# - Changed extension from .jl to .jlt to avoid spurious IDE errors
# - Changed quite a lot to allow deployment to another repo

# Template: docs_index.md
# This is the template templates\docs\src\index.md of PkgTemplates v0.7.18 with,
# - Currently, nothing changed.

# ==================================================================================
#                Type definitions
# ==================================================================================

using PkgTemplates: @plugin, @with_kw_noshow, Plugin, FilePlugin

@plugin struct GitPagesDoc <: FilePlugin
    privaterepo::Bool = false              # true if this package will upstream-ed to a private GitHub repo
    deploy_gituser::StrOpt = nothing       # IF nothing: deploy doc in the package repo and in gh-pages branch
    deploy_gitrepo::StrOpt = nothing       # deploy doc into repo "github/ylvain/PkDoc"
    deploy_branch::StrOpt = nothing        # deploy doc into branch main of the above repo
    deploy_subdir::StrOpt = nothing        # If nothing deploys at the root ("/") of the target repo filsystem
                                           # If "<PKG>" deploys at "/PkgRepoName" where PkgRepoName is the name of the packge repo
end

# ==================================================================================
#                Basics accessors
# ==================================================================================

function getplugin(::Type{T}, t::Template) where {T<:Plugin}
    idx = findfirst(x -> x isa T, t.plugins)
    isnothing(idx) && error("A $T plugin must be declared in the template")
    return t.plugins[idx] :: T
end

function isprivaterepo(t::Template)
    getplugin(GitPagesDoc, t).privaterepo
end

function package_reponame(t::Template, pkg::AbstractString)
    getplugin(Git, t).jl ? pkg * ".jl" : pkg
end

function userrepo_code(t::Template, pkg::AbstractString)
    t.user * "/" * package_reponame(t, pkg)
end

function hostuserrepo_code(t::Template, pkg::AbstractString)
    t.host * "/" * userrepo_code(t, pkg)
end

function userrepo_docs(t::Template, pkg::AbstractString)
    c = getplugin(GitPagesDoc, t)
    p = package_reponame(t, pkg)

    if isnothing(c.deploy_gituser)
        "$(t.user)/$p"
    else # Deploymant to another repo
        "$(c.deploy_gituser)/$(c.deploy_gitrepo)"
    end
end

function hostuserrepo_docs(t::Template, pkg::AbstractString)
    t.host * "/" * userrepo_docs(t, pkg)
end

function deploy_samerepo(t::Template, pkg::AbstractString)
    userrepo_code(t, pkg) == userrepo_docs(t, pkg)
end

function deploy_docdir(t::Template, pkg::AbstractString)
    c = getplugin(GitPagesDoc, t)
    if isnothing(c.deploy_subdir)
        return nothing
    end

    if c.deploy_subdir == "<PKG>"
        package_reponame(t, pkg)
    else
        c.deploy_subdir
    end
end

function deploy_branch(t::Template, pkg::AbstractString)
    c = getplugin(GitPagesDoc, t)
    if isnothing(c.deploy_branch)
        return deploy_samerepo(t, pkg) ? "gh-pages" : "main"
    end
    return c.deploy_branch
end

function pages_url_base(t::Template, pkg::AbstractString)
    c = getplugin(GitPagesDoc, t)
    p = package_reponame(t, pkg)
    dir_opt = deploy_docdir(t, pkg)
    d = ""
    if !isnothing(dir_opt)
        d = "/" * dir_opt
    end

    if isnothing(c.deploy_gituser)
        "https://$(t.user).github.io/$p" * d
    else
        "https://$(c.deploy_gituser).github.io/$(c.deploy_gitrepo)" * d
    end
end

pages_url_stable(t::Template, pkg::AbstractString) = pages_url_base(t, pkg) * "/stable"
pages_url_dev(t::Template, pkg::AbstractString)    = pages_url_base(t, pkg) * "/dev"

# ==================================================================================
#                Extends sub-environments
# ==================================================================================

const DEP_DOCUMENTER = PackageSpec(;name="Documenter", uuid="e30172f5-a6a5-5a46-863b-614d45cd2de4")
const DEP_TEST       = PackageSpec(;name="Test"      , uuid="8dfed614-e22c-5e08-85e1-65c5234f0b40")

# We cannot extends the way PkgTemplates generates the Test environment without
# creating another full Plugin (that would delete most of the work to the existing
# one). See: PkgTemplates \src\plugins\tests.jl.
# We also avoid to overload "make_test_project" in the above file.
# So we simply add our changes after package creation.
#
# NOTE: pkgconfig_env_test ==> need to commit these

function pkgconfig_env_test(pkg_dir::String) 
    PkgTemplates.with_project(joinpath(pkg_dir, "test")) do 
        # Pkg.add(DEP_TEST) (done by PkgTemples)
        Pkg.add(DEP_DOCUMENTER)
    end
end

# ==================================================================================
#                PkgTemplates
# ==================================================================================

import PkgTemplates: Badge

PkgTemplates.source(::GitPagesDoc) = template("Documenter.yml")
PkgTemplates.destination(::GitPagesDoc) = joinpath(".github","workflows","Documenter.yml")
PkgTemplates.tags(::GitPagesDoc) = "<<", ">>"
PkgTemplates.view(::GitPagesDoc, t::Template, pkg::AbstractString) = Dict(
    "PKG" => pkg,
    "LOCAL_DOC" => deploy_samerepo(t, pkg) ? "yes" : nothing
)

PkgTemplates.make_canonical(::Type{GitPagesDoc}) = pages_url_stable

#
#  This was giving `WARNING: Method definition badges(PkgTemplates.GitHubActions)`
#  during precompilation. So we simply handle the Badge ouself in the README plugin.
#
# Type piracy. All URL generated are of form github.com/{{{USER}}}/{{{PKG}}}.jl
# badges(::GitHubActions : The .jl suffix is always present, event if the Git plugin has jl=false
# badges(::Codecov) : the branch name 'master' is hardcoded! We correct both here.
# badges(::Documenter{GitPagesDoc} : need custom doc URL
# function PkgTemplates.badges(::GitHubActions)
#     Badge("Build Status",
#     "https://github.com/{{{USER}}}/{{{PKG_REPO}}}/workflows/Tests/badge.svg",
#     "https://github.com/{{{USER}}}/{{{PKG_REPO}}}/actions")
# end
# function PkgTemplates.badges(::Codecov)
#     Badge("Coverage",
#     "https://codecov.io/gh/{{{USER}}}/{{{PKG_REPO}}}/branch/main/graph/badge.svg{{{BADGE_TOKEN}}}",
#     "https://codecov.io/gh/{{{USER}}}/{{{PKG_REPO}}}")
# end
# function PkgTemplates.badges(::Documenter{GitPagesDoc})
#     [Badge("Stable", "https://img.shields.io/badge/docs-stable-blue.svg", "{{{DOC_URL}}}/stable"),
#      Badge("Dev",    "https://img.shields.io/badge/docs-dev-blue.svg",    "{{{DOC_URL}}}/dev")   ]
# end

function PkgTemplates.user_view(::Documenter{GitPagesDoc}, t::Template, pkg::AbstractString)
    Dict(
        "HAS_DEPLOY" => true,
        # The repo into which the doc is deployed
        "DEPLOY_REPO" => userrepo_docs(t, pkg),
        # A sub-dir of root into which the doc is deployed (maybe nothing)
        "DEPLOY_DIR" => deploy_docdir(t, pkg),
        # The branch of the doc repo under which we deploy
        "DEPLOY_BRC" => deploy_branch(t, pkg),
        # The source code repo from which the doc is built
        # Used to build (checkout the repo)
        # Used in the doc to link back to the code repo
        "REPO" => hostuserrepo_code(t,pkg),

    )
end

function PkgTemplates.user_view(::Readme, t::Template, pkg::AbstractString)
    reponame = package_reponame(t, pkg)
    Dict(
        "TODAY" => today(),
        "USER"  => t.user,
        "PKG_REPO" => reponame,
        "DOC_URL" => pages_url_base(t, pkg),
        "BADGE_TOKEN" => isprivaterepo(t) ? "?token=SOME_10_CHARS_STRING" : "",
        "REMOTE_DOC_URL" => deploy_samerepo(t, pkg) ? nothing : "https://" * hostuserrepo_docs(t, pkg),
        "REMOTE_DOC" => deploy_samerepo(t, pkg) ? nothing : userrepo_docs(t, pkg),
        "PRIVATE_REPO" => isprivaterepo(t) ? "yes" : nothing,
        "CODECOV_HOME" => "https://app.codecov.io/gh/$(t.user)",
        "CODECOV_PKG_SETTING" => "https://app.codecov.io/gh/$(t.user)/$reponame/settings",
        "GITHUB_PKG_SETTING_SECRETS" => "https://github.com/$(t.user)/$reponame/settings/secrets/actions",
    )
end
