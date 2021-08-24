# TESTED WITH [14b8a8f1] PkgTemplates v0.7.18

module PkgCreate

using Pkg
using Dates
using PkgTemplates

using ..DevEnvConfig: devEnvConfig_src_path

const StrOpt = Union{String,Nothing}
const BoolOpt = Union{Bool,Nothing}

function template(filename::String)
    joinpath(devEnvConfig_src_path(), "pkg", "templates", filename)
end

include("customize.jl")
using ..GitTools
using ..DevEnvConfig: Success, Warning, Error

# DOCUMENTED as `newpkg` in module DevEnvConfig
function create(pkname::String;
    private::Bool,
    dir::StrOpt=nothing,
    docrepo::StrOpt=nothing,
    useextjl::BoolOpt=nothing,
    generalregistry::BoolOpt=nothing,
    license::StrOpt=nothing,
    testing_gitconfig=nothing)

    # Default: a public repo may be able to register latter, a private repo /cannot/
    generalregistry = something(generalregistry, !private)
    # Default: private repo has NO .jl extension, public repo NEED it to register to General
    useextjl = something(useextjl, !private)

    gitconfif = if isnothing(testing_gitconfig); GitTools.checkconfig(); else testing_gitconfig end
    tgtdir = something(dir, get(ENV, "JULIA_PKG_DEVDIR", "?"))
    warning = false

    if tgtdir == "?"
        @error "No target directory provided !
        Either define the environment variable JULIA_PKG_DEVDIR,
        or pass the directory with optional argument `dir`."
        return Error
    end

    try
        tgtdir = realpath(tgtdir)
    catch
        @error "The deployment path '$(tgtdir)' does not exist !"
        return Error
    end

    pkpath = joinpath(tgtdir, pkname)
    @info "The package $(pkname) will be created at $(pkpath)"
    if ispath(pkpath)
        @error "The path '$(pkpath)' already exist !"
        return Error
    end

    if generalregistry
        if private
            @error "Defined to both deploy into a private repo and register to the General registry.
            Only public package can be registred in General.
            Set `generalregistry` to `false` or `nothing` (default)."
            return Error
        end
    
        if !useextjl
            @error "Package was requested or inferred to be published into the General registry.
            The repo must use the .jl extension. See `generalregistry` and `!useextjl`."
            return Error
        end
        
        if !isnothing(docrepo)
            @error "Package was requested or inferred to be published into the General registry.
            The documentation should be deployed locally in the package repo,
            leave the `docrepo` argument to its default value of `nothing`"
            return Error
        end
    
        if isnothing(license)
            license = "MIT"
            @warn "Package was requested or inferred to be published into the General registry.
            The license was undefined. Forcing the license to `MIT`.
            An OSI-approved license is required to register the General registry.
            You may choose another OSI-approved license by using the `license` keyword argument."
            warning = true
        end
    end

    if gitconfif.def_branch != "main"
        @error "The local Git default branch should be configured to `main`.
        Execute: git config --global init.defaultBranch main"
        return Error
    end

    if private && isnothing(docrepo)
        @warn "This package is setup to deploy documentation to its own repo.
        This package is also setup to deploy to a private repo. If you have a
        free GitHub account you will NOT be able to enable Pages on this repo.
        You will thus not be able to access the documentation web site at all.
        If you want the repo of the package to be private, then first create
        another public GitHub repo to host the packages documentation and regenerate
        this package to deploy the documentation to the public doc repo."
        warning = true
    end    

    pkgconfig = Template(;
        # authors="name <email>"            # Default value from the global Git config (user.name and user.email).
        user=gitconfif.user_github,         # hosting service username, default value from Git config (github.user)
        dir=tgtdir,                         # Directory to place created packages, default to JULIA_PKG_DEVDIR environment variable.
        host="github.com",                  # URL to the code hosting service where packages will reside.
        julia=v"1.6.0",                     # Minimum allowed Julia version for this package

        plugins = [

        !License,                           # no default license, we add it below if needed

        SrcDir(;                             # generate the file in the src directory
            file=template("module.jlt"),     # Custom template, more exemples
        ),

        ProjectFile(; version=v"0.1.0"),     # default Project.toml file

        Tests(;                              # create /test 
            file=template("runtests.jlt"),   # Custom template, run doc-tests
            project=true),                   # always use subproject (test specific dependencies of Julia >1.2)

        Readme(; destination="README.md",    # README file. File destination, relative to the repository root.
            file=template("README.md"),      # We use a custome template
            inline_badges=false,             # IGNORED by the custom README template. Badge are never inline with the title.
            badge_order=[                    # Order of the README.md Badges generated by each plugin
                Documenter{GitPagesDoc},     # First the Dev/Stable doc links
                GitHubActions                # then the status of the CI Tests
            ]),

        Git(; name=gitconfif.user_local,     # override Git config user.name, allows for testing
            email=gitconfif.user_email,      # override Git config user.email, allows for testing
            branch="main",                   # The desired name of the repository's default branch.
            ssh=true,                        # Whether or not to use SSH for the remote. If left unset, HTTPS is used.
            jl=useextjl,                     # Whether or not to add a .jl suffix to the remote URL.
            manifest=false,                  # Whether or not to commit Manifest.toml.
            gpgsign=false ),                 # Whether or not to sign commits with your GPG key.

        CompatHelper(;
            file=template("CompatHelper.yml"), # Custom template
            destination="CompatHelper.yml",    # Destination of the workflow file, relative to .github/workflows
            cron="0 0 * * 0"),                 # Run weekly, default is "0 0 * * *" which run daily

        GitHubActions(;                      # If using coverage plugins, don't forget to manually add your API tokens as secrets https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets
            file=template("Tests.yml"),      # Use our custom template
            destination="Tests.yml",         # Destination of the workflow file, relative to .github/workflows.
            linux=true,                      # Whether or not to run builds on Linux.
            osx=false,                       # Whether or not to run builds on OSX (MacOS).
            windows=false,                   # Whether or not to run builds on Windows.
            x64=true,                        # Whether or not to run builds on 64-bit architecture.
            x86=false,                       # Whether or not to run builds on 32-bit architecture.
            coverage=true,                   # Publish code coverage? A coverage plugin such as Codecov must also be included.
            extra_versions=["1.6"]),         # Julia versions to test, default: ["1.0", "1.6", "nightly"]

        Codecov(;                          # Sets up code coverage submission from CI to Codecov.
            file=nothing),                 # Template file for .codecov.yml, or nothing to create no file.

        # Coveralls(;                      # Sets up code coverage submission from CI to Coveralls.
        #    file=nothing),                # Template file for .coveralls.yml, or nothing to create no file.

        Documenter{GitPagesDoc}(;               # Sets up documentation generation via Documenter.jl; custom GitPages deployment
            make_jl=template("docs_make.jlt"),  # Template file for make.jl.
            index_md=template("docs_index.md"), # Template file for index.md.
            # logo=Logo()),                     # A Logo containing documentation logo information.
            # canonical_url=...                 # This option is IGNORED by the custom GitPagesDoc
            # makedocs_kwargs::Dict{Symbol,Any} # Extra keyword arguments to be inserted into makedocs.
            devbranch="main",                   # Branch that will trigger docs deployment, or `nothing`
            assets=String[]),                   # Extra assets for the generated site.


        ! TagBot,
        # TagBot(;
        #     destination="TagBot.yml",        # Destination of the workflow file, relative to .github/workflows.
        #     trigger="JuliaTagBot",           # Username of the trigger user for custom regsitries.
        #     token=Secret("GITHUB_TOKEN"),    # Name of the token secret to use.
        #     ssh=Secret("DOCUMENTER_KEY"),    # Name of the SSH private key secret to use.
        #     ssh_password=nothing,            # Name of the SSH key password secret to use.
        #     changelog=nothing,               # Custom changelog template.
        #     changelog_ignore=nothing,        # Issue/pull request labels to ignore in the changelog.
        #     gpg=nothing,                     # Name of the GPG private key secret to use.
        #     gpg_password=nothing,            # Name of the GPG private key password secret to use.
        #     registry=nothing,                # Custom registry, in the format owner/repo.
        #     branches=nothing,                # Whether not to enable the branches option.
        #     dispatch=nothing,                # Whether or not to enable the dispatch option.
        #     dispatch_delay=nothing),         # Number of minutes to delay for dispatch events.

        # Logo(;                             # For Documenter{T} above. Logo information for documentation.
        #     light=nothing,                 # Path to a logo file for the light (default) theme.
        #     dark=nothing)                  # Path to a logo file for the dark theme.

        # BlueStyleBadge()                   # Adds a BlueStyle badge to the Readme file, see: https://github.com/invenia/BlueStyle
        # ColPracBadge()                     # Adds a ColPrac badge to the Readme file, see: https://github.com/SciML/ColPrac
        # Develop()                          # Adds generated packages to the current environment by deving them
        # Citation(;                         # Creates a CITATION.bib file for citing package repositories.
            # readme=false)                  # Whether or not to include a section about citing in the README.
        # RegisterAction(;                   # Add a GitHub Actions workflow for registering a package with the General registry
            # destination="register.yml",    # Destination of the workflow file, relative to .github/workflows.
            # prompt="Version?")             # Prompt for workflow dispatch.
    ]) # myTemplate = Template(; ...

    if generalregistry
        push!(pkgconfig.plugins, RegisterAction(;
            file=template("PublicRegister.yml"),
            destination="PublicRegister.yml",
            prompt="Version to register or component to bump"))
    end

    if isnothing(docrepo)
        push!(pkgconfig.plugins, GitPagesDoc(;
            privaterepo    = private,       # true if this package will be upstream-ed to a private GitHub repo
            deploy_gituser = nothing,       # IF nothing: deploy doc in the package repo and in gh-pages branch
            deploy_gitrepo = nothing,       # deploy doc into repo "github/ylvain/PkDoc"
            deploy_branch  = nothing,       # default to "gh-pages" for same repo
            deploy_subdir  = nothing))      # deploys at the root ("/") of the target repo filsystem
    else
        push!(pkgconfig.plugins, GitPagesDoc(;
            privaterepo    = private,       # true if this package will be upstream-ed to a private GitHub repo
            deploy_gituser = pkgconfig.user, # FIXME: assume the docrepo belong to the same GitHub user
            deploy_gitrepo = docrepo,       # deploy doc into repo "github/deploy_gituser/deploy_gitrepo"
            deploy_branch  = nothing,       # default to "main" for same a doc repo
            deploy_subdir  = "<PKG>"))      # "<PKG>" deploys at "/PkgRepoName" (name of the packge repo)
    end
    
    if !isnothing(license)
        push!(pkgconfig.plugins, License(;
            path=nothing,                  # Path to a custom license file. This keyword takes priority over name.
            name="MIT",                    # See https://github.com/invenia/PkgTemplates.jl/tree/master/templates/licenses
            destination="LICENSE"))        # for the list of open source license that can be given as `name`
    end

    pkgconfig(pkname)

    pkgconfig_env_test(pkpath)
    GitTools.commit(pkpath, "DevEnvConfig newpkg() extensions")

    @info "The package code repo is: $(hostuserrepo_code(pkgconfig, pkname))"
    @info "The package docs repo is: $(hostuserrepo_docs(pkgconfig, pkname))"
    @info "The local package is at $pkpath"
    return warning ? Warning : Success
end

end # module PkgCreate