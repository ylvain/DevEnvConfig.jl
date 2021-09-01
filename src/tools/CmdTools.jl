module CmdTools

function execute(cmd::Cmd)
    out = Pipe()
    err = Pipe()
  
    process = run(pipeline(ignorestatus(cmd), stdout=out, stderr=err))
    close(out.in)
    close(err.in)
    stdout = @async String(read(out))
    stderr = @async String(read(err))
    (
      out = fetch(stdout), 
      err = fetch(stderr),  
      code = process.exitcode
    )
end

end # module CmdTools