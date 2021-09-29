module SysImageBuilder
using ..DevEnvConfig: devEnvConfig_pkg_path
using ..RuntimeContext
using Dates
using UUIDs
using Pkg

export ImageSpec
export name, path, size, date, exists, delete, build

import Base: repr, size

const JULIA_TARGET = "native"

const VERSION_PackageCompiler = "1.3.0" # must be a string
const ENVPATH_SEPARATOR = @static Sys.iswindows() ? ";" : ":"
const IMAGE_FILENAME = "sys.jsi"

const BOOTSTRAP_LOCAL = true
const BOOTSTRAP_PATH = devEnvConfig_pkg_path()
const BOOTSTRAP_SPEC = """PackageSpec(path = raw"$BOOTSTRAP_PATH")"""

#region ImageSpec

function isvalidname(name::String)
    check(c::AbstractChar) = isletter(c) || isdigit(c) || c == '_' || c == '-'
    return isascii(name) && all(check, name)
end

function checkvalidname(name::String)
    isvalidname(name) || error("Invalid image name '$name'. Only ascii letters, digits, '_', '-' are allowed.")    
end

struct ImageSpec
    name::String
    extends:: Union{ImageSpec,Nothing}
    function ImageSpec(name::String)
        checkvalidname(name)
        new(name, nothing)
    end
    function ImageSpec(name::String, extends::ImageSpec)
        checkvalidname(name)
        new(name, extends)
    end
end

function repr(s::ImageSpec)
    # Must be a true repr. Used to generate code.
    # TODO: Test with eval(Meta.parse(repr(a))) == a
    if isnothing(s.extends)
        """ImageSpec("$(s.name)")"""
    else
        """ImageSpec("$(s.name)",$(repr(s.extends)))"""
    end
end

name(s::ImageSpec)   = s.name
path(s::ImageSpec)   = joinpath(RuntimeContext.builddevenv_path(), name(s), IMAGE_FILENAME)
size(s::ImageSpec)   = round(filesize(path(s)) / (1 << 20); digits=0) # 0 MB if not exists
date(s::ImageSpec)   = Dates.unix2datetime(mtime(path(s)))            # epoc if not exists
exists(s::ImageSpec) = isfile(path(s))

#endregion

#region Julia isolated invokation

function julia_invoke_cmd()
    jr = escape_string(RuntimeContext.julia_executable())
    return `$jr --startup-file=no --history-file=no --warn-overwrite=yes --cpu-target $JULIA_TARGET --quiet -t 1`
end

function julia(;    
    project::Union{String,Nothing} = nothing,
    source::Union{String,Nothing} = nothing,
    code::Union{String,Nothing} = nothing,
    trace::Union{String,Nothing} = nothing,
    indir::Union{String,Nothing} = nothing,
    image::Union{ImageSpec,Nothing} = nothing,
    optlvl::Int = 2,
    dbglvl::Int = 1,
    debug::Bool = false, 
    )
    nrmpath(s) = isnothing(s) ? nothing : realpath(expanduser(s))
    escape(s) = isnothing(s) ? nothing : escape_string(s)
    addarg(cmd::Cmd, arg::Cmd) = Cmd(Cmd(vcat(cmd.exec, arg.exec)), cmd.ignorestatus, cmd.flags, cmd.env, cmd.dir)

    addproj(cmd::Cmd, ::Nothing) = cmd
    addproj(cmd::Cmd, val::String) = addarg(cmd, `--project=$val`)

    addflag(cmd::Cmd, ::String, ::Nothing) = cmd
    addflag(cmd::Cmd, flag::String, val::String) = addarg(cmd, `$flag $val`)
    addflag(cmd::Cmd, flag::String, val::Int) = addarg(cmd, `$flag $val`)

    # FIXME: https://docs.julialang.org/en/v1/manual/environment-variables/#JULIA_LOAD_PATH
    # "JULIA_LOAD_PATH"  => ":" as per the doc. After test, must use the ENVPATH_SEPARATOR of the platform
    
    dir = isnothing(indir) ? pwd() : nrmpath(indir)
    img = isnothing(image) || isnothing(image.extends) ? nothing : nrmpath(path(image.extends))
    isnothing(img) || isfile(img) || error("Internal error. Image $image depends on $img which does not exists.")

    # We will inherit the env. var. of the exec system call (e.g. all USER/MACHINE scoped one on Windows)
    # We override the variable that may cause issue. TODO: We probably need to add more here...
    # JULIA_PKG_DEVDIR, ...
    env = Dict(
        "JULIA_DEPOT_PATH" => join(RuntimeContext.depotdevenv(), ENVPATH_SEPARATOR),
        "JULIA_LOAD_PATH"  => ENVPATH_SEPARATOR,
    )
    
    cmd = julia_invoke_cmd()
    cmd = addproj(cmd, nrmpath(project))
    cmd = addflag(cmd, "--sysimage", escape(img))
    cmd = addflag(cmd, "--trace-compile", escape(trace))

    cmd = addflag(cmd, "-O", optlvl)
    cmd = addflag(cmd, "-g", dbglvl)
    cmd = addflag(cmd, "-e", code)
    cmd = addflag(cmd, "--", nrmpath(source))
    cmd = Cmd(cmd; env, dir)

    if !isnothing(code)
        printstyled("Julia execution code\n"; color=:red)
        printstyled(code; color=:blue)
        print('\n')
    end

    printstyled("Julia execution starts...\n"; color=:red)
    !debug || dump(cmd)
    run(cmd)
    printstyled("Julia execution completed.\n"; color=:red)
end

#endregion

#region Project generation

function create_project_lazy(path::String, name::String)
    path_proj = joinpath(path, name)
    file_proj = joinpath(path_proj, "Project.toml")
    isfile(file_proj) && return path_proj

    ver = Base.VERSION
    mkpath(path_proj)
    open(file_proj, "w") do io
        print(io, """
        name = "$(name)"
        uuid = "$(uuid4())"
        authors = [""]
        version = "0.1.0"

        [compat]
        julia = "$(ver.major).$(ver.minor)"
    """)
    end
    path_src = joinpath(path_proj, "src")
    mkpath(path_src)
    open(joinpath(path_src, "$name.jl"), "w") do io
        print(io, """
        module $(name)
        end
        """)
    end
    return path_proj
end

function setup_project_builder_lazy()
    path_root = RuntimeContext.builddevenv_path()
    path_proj = joinpath(path_root, "Builder")
    file_proj = joinpath(path_proj, "Project.toml")
    isfile(file_proj) && return path_proj

    create_project_lazy(path_root, "Builder")
    julia(;project=path_proj, code="""
        using Pkg
        using UUIDs
        compiler = PackageSpec("PackageCompiler", UUID("9b87118b-4619-50d2-8e1e-99f35a4d4d9d"), v"$VERSION_PackageCompiler")
        self = $BOOTSTRAP_SPEC
        Pkg.add(compiler)
        $(BOOTSTRAP_LOCAL ? "Pkg.develop(self)" : "Pkg.add(self)")
        println("Created project \$(Base.ACTIVE_PROJECT[])")
    """)

    return path_proj
end

#endregion

function build_init(s::ImageSpec)
    opt = Base.JLOptions()
    default_jsi = !convert(Bool, opt.image_file_specified)
    current_img = unsafe_string(opt.image_file)
    printstyled("PackageCompiler invoked in environment:\n";color=:yellow)
    printstyled("           PWD: $(pwd())\n"; color=:blue)
    printstyled("ACTIVE_PROJECT: $(Base.ACTIVE_PROJECT[])\n"; color=:blue)
    printstyled("     LOAD_PATH: $(Base.load_path()[1])\n"; color=:blue)
    printstyled("    DEPOT_PATH: $(Base.DEPOT_PATH[1])\n"; color=:blue)
    printstyled("  TARGET IMAGE: $(path(s))\n";   color=:blue)
    printstyled(" CURRENT IMAGE: $current_img\n"; color=:blue)
    printstyled("   DEFAULT JSI: $default_jsi\n"; color=:blue)

    if !isnothing(s.extends) && current_img != path(s.extends)
        error("Internal error. Current image should be $(path(s.extends))")
    end 
end

function build_finish(s::ImageSpec)
    printstyled("Build completed: $(size(s)) MB, $(date(s))\n";color=:yellow)
end

function build_stdlib_min(create::Function, s::ImageSpec)
    # If we use [filter_stdlibs=true] we can create the absolute minimal image.
    # - It contains only Core+Base, the loaded_modules at Core,Base,Main
    # - There is a very limited REPL (not color, etc.)
    # - Thre size is about 63M
    # By including the StdLib the size rise to about 100M (without any precomp)

    packages = Symbol[] # none !
    params = (
        sysimage_path=IMAGE_FILENAME,
        project=("./Build"),
        precompile_execution_file = String[],
        precompile_statements_file = String[],
        incremental = false,
        filter_stdlibs = false,
        replace_default = false,
        version = Base.VERSION,
        cpu_target = "native",
    )    

    build_init(s)
    if exists(s)
        printstyled("Building Base+Stdlib: image file exists. Doing nothing.\n";color=:light_red)
    else
        printstyled("Building Base+Stdlib from scratch. No precompilation.\n";color=:yellow)
        invoke(create, Tuple{Vector{Symbol}}, packages; params...) # no extra packages 
    end
    build_finish(s)
end

function build_stdlib(create::Function, s::ImageSpec)
    packages = Symbol[] # none !
    params = (
        sysimage_path=IMAGE_FILENAME,
        project=("./Build"),
        precompile_execution_file = String[],
        precompile_statements_file = String["stdlib.jl"],
        incremental = true,
        filter_stdlibs = false,
        replace_default = false,
        version = Base.VERSION,
        cpu_target = "native",
    )    

    build_init(s)
    if exists(s)
        printstyled("Building Base+Stdlib: image file exists. Doing nothing.\n";color=:light_red)
    else
        printstyled("Building Base+Stdlib from scratch. No precompilation.\n";color=:yellow)
        invoke(create, Tuple{Vector{Symbol}}, packages; params...) # no extra packages 
    end
    build_finish(s)
end

function delete(s::ImageSpec)
    build_path = dirname(path(s))
    contains(build_path, RuntimeContext.DEVENV_DIRNAME) || error("delete")
    rm(build_path; recursive=true, force=true)    
end

#  $ jr -J sys.jsi
#  - does not lock sys.jsi
#  - it is possible to delete it will julia is running
#  - but some operation (at least using a package,, precomp check) try to access it
#  => [ Info: Precompiling BenchmarkTools [6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf]
#     ERROR: could not load library "C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\stdlib-min\sys.jsi"
#     The specified module could not be found.
#     ERROR: IOError: write: broken pipe (EPIPE)
#

function build(s::ImageSpec)
    build_path = dirname(path(s))

 # FIXME debug helper
 #   ispath(build_path) && error("Image $(name(s)) exists already at $(path(s)). Call delete(..) before build(...) if needed.")
    mkpath(build_path)

    builder = setup_project_builder_lazy()
    create_project_lazy(build_path, "Build")

    call =""
    if name(s) == "stdlib-min"
        call = "build_stdlib_min"
    elseif name(s) == "stdlib"
        call = "build_stdlib"
    else
        error("unknow image")
    end

    julia(project=builder, image=s, indir=dirname(path(s)), code="""
        using PackageCompiler
        using DevEnvConfig.SysImageBuilder
        image = $(repr(s))
        ENV["JULIA_DEBUG"]="all"
        SysImageBuilder.$call(PackageCompiler.create_sysimage, image)
    """)
end

# julia> build(ImageSpec("stdlib-min"))
# Julia execution code
#     using PackageCompiler
#     using DevEnvConfig.SysImageBuilder
#     image = ImageSpec("stdlib-min")
#     SysImageBuilder.build_stdlib_min(PackageCompiler.create_sysimage, image)
# Julia execution starts...
# PackageCompiler invoked in environment:
#            PWD: C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\stdlib-min
# ACTIVE_PROJECT: C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\Builder
#      LOAD_PATH: C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\Builder\Project.toml
#     DEPOT_PATH: C:\Users\Yoann\.julia\devenvmgr\depot
#   TARGET IMAGE: C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\stdlib-min\sys.jsi
#  CURRENT IMAGE: C:\Users\Yoann\AppData\Local\Programs\Julia-1.6.1\lib\julia\sys.dll
#    DEFAULT JSI: true
# Building Base+Stdlib from scratch. No precompilation.
#     Updating registry at `C:\Users\Yoann\.julia\devenvmgr\depot\registries\General`
#     Updating git-repo `https://github.com/JuliaRegistries/General.git`
#   No Changes to `C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\stdlib-min\Build\Project.toml`
#   No Changes to `C:\Users\Yoann\.julia\devenvmgr\v1.6-x86_64-w64-mingw32-haswell\stdlib-min\Build\Manifest.toml`
# [ Info: PackageCompiler: creating base system image (incremental=false)...
# [ Info: PackageCompiler: creating system image object file, this might take a while...
# Build completed: 99.0 MB, 2021-09-07T14:12:01.292
# Julia execution completed.

end # module SysImageBuilder