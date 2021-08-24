using Documenter: DocMeta, doctest
using DevEnvConfig
using Test

using ..DevEnvConfig: Success, Warning, Error

const gitconf = DevEnvConfig.GitTools.GitConfig("loc_user", "user@foo.com", "hub_user", "main")

@testset "DevEnvConfig" begin
    @test newpkg("Pk1";dir=mktempdir(),private=false,                  testing_gitconfig=gitconf) != Error
    @test newpkg("Pk2";dir=mktempdir(),private=true,  docrepo="Docs",  testing_gitconfig=gitconf) != Error
end

# Run all doctests in the package. Also run the doctests in docs/src.
# Set manual=false to run only doctest from doc strings in the sources.
# If this is too slow, you can comment it out. The doctests will be run
# anyway by "docs/make.jl" each time the documention is built. If you
# comment this out, a doctest failure will *not* be detected by the CI
# workflow "Tests.yml" since it only executes this file.

# DocMeta.setdocmeta!(DevEnvConfig, :DocTestSetup, :(using DevEnvConfig); recursive=true)
# doctest(DevEnvConfig; manual = true)
