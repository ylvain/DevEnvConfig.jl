using Documenter: DocMeta, doctest
using DevEnvConfig
using Test

@testset "DevEnvConfig" begin
    # Write your tests here.
end

# Run all doctests in the package. Also run the doctests in docs/src.
# Set manual=false to run only doctest from doc strings in the sources.
# If this is too slow, you can comment it out. The doctests will be run
# anyway by "docs/make.jl" each time the documention is built. If you
# comment this out, a doctest failure will *not* be detected by the CI
# workflow "Tests.yml" since it only executes this file.

# DocMeta.setdocmeta!(DevEnvConfig, :DocTestSetup, :(using DevEnvConfig); recursive=true)
# doctest(DevEnvConfig; manual = true)