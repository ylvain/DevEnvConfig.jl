
Find a way to remove type piracy... we'll need to handle badge ourself...

```
julia> using DevEnvConfig
[ Info: Precompiling DevEnvConfig [2baef489-5d3b-4196-bdcc-c190e0714a0d]
WARNING: Method definition make_test_project(AbstractString) in module PkgTemplates at C:\Users\Yoann\.julia\packages\PkgTemplates\hTyXB\src\plugins\tests.jl:46 overwritten in module PkgCreate at c:\Sources\julia\DevEnvConfig\src\pkg\customize.jl:143.
  ** incremental compilation may be fatally broken for this module **

WARNING: Method definition badges(PkgTemplates.GitHubActions) in module PkgTemplates at C:\Users\Yoann\.julia\packages\PkgTemplates\hTyXB\src\plugins\ci.jl:63 overwritten in module PkgCreate at c:\Sources\julia\DevEnvConfig\src\pkg\customize.jl:168.
  ** incremental compilation may be fatally broken for this module **

WARNING: Method definition badges(PkgTemplates.Codecov) in module PkgTemplates at C:\Users\Yoann\.julia\packages\PkgTemplates\hTyXB\src\plugins\coverage.jl:19 overwritten in module PkgCreate at c:\Sources\julia\DevEnvConfig\src\pkg\customize.jl:177.
  ** incremental compilation may be fatally broken for this module **
```

## General
* Use Preferences.jl to manage settings/default for this pkg
    * See: https://github.com/JuliaPackaging/Preferences.jl
    * Note: add a .gitignore for LocalPreferences.toml
* (?) we *could* use Artifact for templates data etc... but it seems overkill

## Pkg Creation

* take a set of packages (i.e. an initial env) and add them to the project
  (if public registry, also add the [compat] entry so the initial registration succeed)
  (maybe also for others registry ? this is good practice)
* Use the PkgTemplates option to `dev` the newly created packages
* Add an option "minimal=true" to remove all the examples/docs we have in [README, src/Pkg.jl, test/runtests.jl]
* (?) redirect output when creating the packages with PkgTemplates to remove all
the message generated by Pkg. Only keep errors if any (should not be possible to error here, if we
add the external package ourself)
* Use LibSSH2_jll to help generate the keys for: doc-repo access token, git hub access itself ?.
Note: we cannot easiuly use the open ssh install by GitForWindows because it does NOT ouput cleanly to stdout !
* If we can get access to the GitHub api... well... we could do a LOT!

## GutHub

* When we do the initial push to the repo, GitHub does NOT create all the Actions from
the workflow files... it's a bug on their side (touching the .yml files and commit will
create the Actions). Seems related to the fact that the Tests workflow start running
immediatly...

## Documenter

* The links to `stable` and `dev` are always active trough the Badges,
il would be nice to push a page saying that the doc is not yet generated
and what action will generate it. Now it 404.
* find a way to change the color of symbol `code` in dark theme (dark red is not nice)
* add a kind static-site pregen (use Mustache.jl like PkgTemplate), purpose
    * allows to cross links between packages doc using [mylink]({{OtherPkg}}base-permalink)
    * probably a lot of others usefull things

## SysIaage

* TODO