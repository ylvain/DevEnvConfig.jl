module GitTools

struct GitConfig
    user_local::String
    user_github::String
    def_branch::String
end

# We do not use the StdLib LibGit2
# We actually want to check that Git is installed locally and can be run...

function tryversion()
    try
        strip(read(`git version`, String))
    catch
        nothing
    end
end

function user_local()
    try # fail if the option is not defined
        strip(read(`git config user.name`, String))
    catch
        nothing
    end
end

function user_github()
    try # fail if the option is not defined
        strip(read(`git config github.user`, String))
    catch
        ""
    end
end

function defaultbranch()
    try # fail if the option is not defined
        strip(read(`git config init.defaultBranch`, String))
    catch
        ""
    end
end


function checkconfig()

    version = tryversion()
    if isnothing(version)
        @error "Git does not seem installed! The command `git version` failed.
        Install Git or ensure that it is in the PATH, on Windows you may run
        from the Git Bash shell"
    end
    @info "Git installed: $version"

    user_git = user_github()
    if isnothing(user_git)
        @error "No GitHub user defined. Execute the following command
        to configure the name of your GitHub account.
                git config --global github.user your_account_name
        "
    end
    @info "GitHub account: $user_git"

    user_loc = user_local()
    if isnothing(user_loc)
        @error "No local Git user defined. Execute the following command
        to configure the local user. It is recommanded to user the same
        user name as your GitHub user account.
                git config --global user.name \"your_user_name\"
        "
    end
    @info "Git user: $user_loc"

    branch = defaultbranch()
    if isnothing(branch)
        @error "No default branch name defined. Execute
                git config --global init.defaultBranch main"
    end
    
    return GitConfig(user_loc, user_git, branch)

end

end # module GitTools