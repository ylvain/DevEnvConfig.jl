module RuntimeContext

const DEVENV_DIRNAME = "devenvmgr"
const DEPOT_DEVENV = Ref("")
const BUILD_DEVENV = Ref("")

installpath() = dirname(Sys.BINDIR)

depotuser_path() = joinpath(homedir(), ".julia")
depotlocal_path() = joinpath(installpath(), "local", "share", "julia")
depotglobal_path() = joinpath(installpath(), "share", "julia")

julia_executable() = joinpath(Sys.BINDIR, Sys.iswindows() ? "julia.exe" : "julia") 

function depotdevenv_path()
    DEPOT_DEVENV[] != "" && return DEPOT_DEVENV[]

    path = joinpath(depotuser_path(), DEVENV_DIRNAME, "depot")
    path_gen = joinpath(depotuser_path(), "registries", "General")
    path_reg = joinpath(path, "registries")
    link_gen = joinpath(path_reg, "General")
    mkpath(path)
    mkpath(path_reg)
    # avoid cloning General - Windows: should do a Junction, no special rights
    ispath(link_gen) || symlink(path_gen, link_gen; dir_target=true)
    DEPOT_DEVENV[] = path
    return path
end

function builddevenv_path()
    BUILD_DEVENV[] != "" && return BUILD_DEVENV[]
    # Note: For julia <= 1.7 CPU_NAME resolve to the LLVM target name.
    # We build sysimage with the "native" target, which is CPU_NAME.
    ver = Base.VERSION
    sys = "v$(ver.major).$(ver.minor)"
    arch = Sys.MACHINE # x86_64-w64-mingw32
    target = Sys.CPU_NAME # haswell 
    path = joinpath(depotuser_path(), DEVENV_DIRNAME, "$sys-$arch-$target")
    mkpath(path)
    BUILD_DEVENV[] = path
    return path
end

depotdevenv() = [depotdevenv_path(); depotlocal_path(); depotglobal_path()]

depotstandard() = [depotuser_path(); depotlocal_path(); depotglobal_path()]

isdepotstandard() = DEPOT_PATH == depotstandard()

# function ensure_init()
#     # Helper for Revise dev cycle
#     DEPOT_DEVENV[] = ""
#     BUILD_DEVENV[] = ""
#     depotdevenv_path()
#     builddevenv_path()
# end

end # module RuntimeContext