## Tracing runc "container start" invocations

This simple bash script can inject an strace of the
runc process when called via containerd in Docker 1.11 and up.

### Installation

In Docker 1.11 and up, the Docker daemon will run a containerd
instance which will execute a binary named `docker-runc` found
in the `$PATH`.

 1. Find where the current `docker-runc` binary is located on your
system, e.g. `/usr/local/bin`.
 2. Move this current binary to `docker-runc-original`
 3. Copy the `docker-runc` script from this repository to a location
 along the `$PATH`
 4. To turn on strace-ing of container start, start the Docker
 daemon with the following environment variable added: "`STRACE_RUNC=1`"
 
### Running

When you run containers, a capture of the strace for each container
will be stored in `/tmp/strace-{containerID}.log`.

Other invocations of runc (other than start) are currently not run
via strace.

Restarting the daemon without `STRACE_RUNC=1` will stop the wrapper
script from running strace on `runc start` invocations.

### Uninstall

Remove the wrapper script and rename `docker-runc-original` back to
`docker-run` along your `$PATH`.