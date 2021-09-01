module GitTools

struct GitConfig
    user_local::String
    user_email::String
    user_github::String
    def_branch::String
    GitConfig() = new("","","","")
    GitConfig(github::String ; user::String, email::String, branch::String) = new(user, email, github, branch)
end

# We do not use the StdLib LibGit2
# We actually want to check that Git is installed locally and can be run...

const requireversion = v"2.10"
const gitversion = Ref("<undef>")
function queryversion()
    try
        v = strip(read(`git version`, String))
        if !startswith(v, "git version ")
            @warn "git is installed but its version string does not start with `git version`, assume $v >= $requireversion."
            return v # we assume it is at least $requireversion...
        else
            v = SubString(v, length("git version ")+1)
            m = match(r"^\d+\.\d+", v) # major.minor
            if isnothing(m) 
                @warn "git is installed with strange version string, $v >= $requireversion."
                return v # we assume it is at least $requireversion...
            else                
                if VersionNumber(m.match) < requireversion
                    @error "git is installed at version $(m.match), we require >= $requireversion."
                    return "" # we known our config will fail
                end
                return v # cleaned version string
            end
        end
        return v
    catch # git not installed
        return ""
    end
end

function isinstalled()
    if gitversion[] == "<undef>"
        gitversion[] = queryversion()
    end
    return gitversion[] != ""
end

function isgitrepo(path::String)
    ispath(path) && ispath(joinpath(path, ".git"))
end

function readconfig(keyname::String)
    try
        String(strip(read(`git config $keyname`, String)))
    catch
         ""
    end
end

function getconfig(path::Union{String,Nothing}=nothing)
    conf = GitConfig()
    isinstalled() || return conf

    dir = nothing
    if !isnothing(path)
        dir = pwd()
        cd(path) # OK to fail if invalid
    end

    try
        conf = GitConfig(readconfig("github.user");
            user   = readconfig("user.name"),
            email  = readconfig("user.email"),
            branch = readconfig("init.defaultBranch"))
    finally
        isnothing(dir) || cd(dir)
    end

    return conf
end

function commit(gitrepo::String, msg::String)
    curr = pwd()
    cd(gitrepo)
    execute(`git commit -a -m "$msg"`)
    cd(curr)
end

# function checkconfig()

#     version = tryversion()
#     if isnothing(version)
#         @error "Git does not seem installed! The command `git version` failed.
#         Install Git or ensure that it is in the PATH, on Windows you may run
#         from the Git Bash shell"
#     end
#     @info "Git installed: $version"

#     user_git = user_github()
#     if isnothing(user_git)
#         @error "No GitHub user defined. Execute the following command
#         to configure the name of your GitHub account.
#                 git config --global github.user your_account_name
#         "
#     end
#     @info "GitHub account: $user_git"

#     user_loc = user_local()
#     if isnothing(user_loc)
#         @error "No local Git user defined. Execute the following command
#         to configure the local user. It is recommanded to user the same
#         user name as your GitHub user account.
#                 git config --global user.name \"your_user_name\"
#         "
#     end
#     @info "Git user: $user_loc"

#     user_mail = user_email()
#     if isnothing(user_mail)
#         @error "No user email defined. Execute the following command
#         to configure the name of your local git contact email.
#                 git config --global user.email name@example.com
#         "
#     end
#     @info "Git email: $user_mail"

#     branch = defaultbranch()
#     if isnothing(branch)
#         @error "No default branch name defined. Execute
#                 git config --global init.defaultBranch main"
#     end
    
#     return GitConfig(user_loc, user_mail, user_git, branch)

# end

end # module GitTools