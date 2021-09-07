module RuntimeEnv

# TODO (MAYBE): correct wrong check for path separators: Win ';' Unix: ':'
const PATH_SEPS = r";|:"

#  using LinearAlgebra
#  BLAS.vendor()
#  BLAS.get_num_threads()
#  BLAS.openblas_get_config()  (! if different vendor)
#
#  On Linux: result of `lscpu`

#region TomlDict

# Allows the keep the TOML table in the order they are declared
# TODO: change this DataStructures.OrderedDict 
const IDict = Base.ImmutableDict
IDict{K,Any}(KV::Pair{K,V}) where {K,V} = IDict{K,Any}(KV[1], KV[2])
IDict{K,Any}(dict::IDict{K,Any}, KV::Pair{K,V}) where {K,V} = IDict{K,Any}(dict, KV[1], KV[2])
function IDict{K,Any}(ps::AbstractVector{Union{Nothing,Pair{K,V}}}) where {K,V}
    d = IDict{K,Any}()
    for i ∈ reverse(eachindex(ps))
        if !isnothing(ps[i])
            d = IDict{K,Any}(d, ps[i])
        end
    end
    return d
end
function IDict{K,Any}(ps::AbstractVector{Pair{K,V}}) where {K,V} 
    d = IDict{K,Any}()
    for i ∈ reverse(eachindex(ps))
        d = IDict{K,Any}(d, ps[i])
    end
    return d
end
const TomlDict = IDict{String, Any}

#endregion

function julia_system()

    # $ export JULIA_LLVM_ARGS=--version
    # $ jr -e 1
    # LLVM (http://llvm.org/):
    #   LLVM version 11.0.1jl
    #   Optimized build.
    #   Default target: x86_64-w64-mingw32
    #   Host CPU: haswell
    #
    # $ export JULIA_LLVM_ARGS=--help
    # $ .... long list ....


    # loadavg                0 bytes typeof(Base.Sys.loadavg)
    # maxrss                 0 bytes typeof(Base.Sys.maxrss)
    # uptime                 0 bytes typeof(Base.Sys.uptime)
    # which                  0 bytes typeof(Base.Sys.which)

    mem_tot = round(Float64(Base.Sys.total_memory())/(1 << 30);digits=1)
    mem_free = round(Float64(Base.Sys.free_memory())/(1 << 30);digits=1)

    nfo = Sys.cpu_info() # Vector{Base.Sys.CPUinfo}, one by HT core

    lsb = "" # code below from stdlib\v1.6\...\InteractiveUtils.jl, versioninfo
    if Sys.islinux()
        try lsb = readchomp(pipeline(`lsb_release -ds`, stderr=devnull)); catch; end
    end
    if Sys.iswindows()
        try lsb = strip(read(`$(ENV["COMSPEC"]) /c ver`, String)); catch; end
    end
    if Sys.isunix()
        lsb *= " uname: " * readchomp(`uname -mprsv`)
    end

    TomlDict([
        "VERSION" => string(Base.VERSION);
        "BINDIR" => Sys.BINDIR;
        "STDLIB" => Sys.STDLIB;
        "JIT" => Sys.JIT;
        "CPU_NAME" => Sys.CPU_NAME;
        "CPU_THREADS" => Sys.CPU_THREADS;
        "WORD_SIZE" => Sys.WORD_SIZE;
        "KERNEL" => string(Sys.KERNEL);
        "ARCH" => string(Sys.ARCH);
        "MACHINE" => Sys.MACHINE;
        "PLATFORM" => lsb;
        "BUILD_STDLIB_PATH" => Sys.BUILD_STDLIB_PATH;
        "WINDOWS_VERSION" => string(Sys.windows_version());
        "PROCESS_TITLE" => Sys.get_process_title();
        "CPU_MODEL" => nfo[1].model;
        "CPU_SPEED" => "$(nfo[1].speed) MHz";
        "CPU_HTCORES" => string(length(nfo));
        "TOTAL_MEM" => "$mem_tot GB";
        "FREE_MEM" => "$mem_free GB";
        "LIBM" =>  Base.libm_name;
        "LLVM" => string("libLLVM-",Base.libllvm_version," (", Sys.JIT, ", ", Sys.CPU_NAME, ")");    
    ])    
end

function host_tools()
    function wch(name)
        try
            string(Sys.which(name))
        catch e
            string(e)
        end
    end
    TomlDict([
        "julia" => wch("julia");
        "ssh" => wch("ssh");
        "git" => wch("git");
        "cmd" => wch("cmd");
        "bash" => wch("bash");
        "code" => wch("code");
        "wt" => wch("wt");
        "winget" => wch("winget");
        "powershell" => wch("powershell");
    ])
end

function dictof(a::AbstractVector)
    IDict{String,Any}([string(i) => string(a[i]) for i ∈ eachindex(a)])
end

function pathlike(value::String)
    dictof(split(value, PATH_SEPS; keepempty=false))
end

function env_context()
    j_any = Set{String}()
    j_pat = Set{String}()
    paths = Set{String}()
    other = Set{String}()

    for var ∈ keys(ENV)
        if contains(var, "JULIA")
            if contains(ENV[var], PATH_SEPS)
                push!(j_pat, var)
            else
                push!(j_any, var)
            end
        elseif contains(ENV[var], PATH_SEPS)
            push!(paths, var)
        else
            push!(other, var)
        end
    end

    a = ["ENV:JULIA" => TomlDict([ var => ENV[var] for var ∈ sort(collect(j_any))])]
    b = ["ENV:(JULIAPATH):"*var => pathlike(ENV[var])  for var ∈ sort(collect(j_pat))]
    c = ["ENV(PATH):"*var => pathlike(ENV[var])  for var ∈ sort(collect(paths))]
    d = ["ENV:OTHERS" => TomlDict([ var => ENV[var] for var ∈ sort(collect(other))])]
    vcat(a,b,c,d)
end

function julia_loaded_modules() 
    # Base.loaded_modules :: Dict{Base.PkgId, Module} 
    # Base.PkgId <: Any
    #   uuid::Union{Nothing, Base.UUID}
    #   name::String
    id(x) = isnothing(x) ? "top-level" : string(x)
    ks = sort(collect(keys(Base.loaded_modules)); lt=(x,y)->x.name<y.name)
    TomlDict([k.name => id(k.uuid) for k ∈ ks])
end

function julia_options()    
    fs = fieldnames(Base.JLOptions)
    op = Base.JLOptions() # Ignore field commands :: Ptr{Ptr{UInt8}}
    str(x::Ptr{<:Integer})= x == C_NULL ? "NULL" : unsafe_string(x)
    ptr(x) = eltype(typeof(x)) <: Integer ? str(x) : string(typeof(x))
    toml(x) = x isa Ptr ? ptr(x) : x isa Number ? x : "?"
    Dict( string(f) => toml(getproperty(op,f)) for f ∈ fs)
end

function full_context()

    # TODO ?
    # Base.DL_LOAD_PATH ->  -> https://docs.julialang.org/en/v1/stdlib/Libdl/

    a = [
        "PROGRAM_FILE" => PROGRAM_FILE;
        "PROGRAM_ARGS" => ARGS;
        "LOAD_PATH" => LOAD_PATH;
        "ACTIVE_PROJECT" => string(Base.ACTIVE_PROJECT[]);
        "SYSTEM" => julia_system();
        "LOAD_PATH_EXP" => dictof(Base.load_path());
        "DEPOT_PATH" => dictof(DEPOT_PATH);
        "WHICH" => host_tools();
    ]

    b = env_context()

    c = [
        "Base_JLOptions" => julia_options();
        "Base_loaded_modules" => julia_loaded_modules();
    ]

    TomlDict(vcat(a,b,c))
end


# using TOML
# function save(file::String)
#     open(file, "w") do io
#         TOML.print(io, full_context())
#     end
# end
# function load(file::String)
#     TOML.parsefile(file)    
# end
# save("env.toml")
# TOML.print(load("env.toml"))

end # module RuntimeEnv
