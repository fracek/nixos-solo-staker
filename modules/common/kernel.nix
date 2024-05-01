{
  boot.kernel.sysctl = {
    # By default, Linux will eagerly use a lot of swap space to take some of
    # the pressure off of the system's RAM. We don't want that. We want it to
    # use all of the RAM up to the very last second before relying on SWAP. The
    # next step is to change what's called the "swappiness" of the system,
    # which is basically how eager it is to use the swap space. There is a lot
    # of debate about what value to set this to, but we've found a value of 6
    # works well enough.
    #
    # We also want to turn down the "cache pressure", which dictates how quickly the
    # server will delete a cache of its filesystem. Since we're going to have a lot
    # of spare RAM with our setup, we can make this "10" which will leave the cache
    # in memory for a while, reducing disk I/O.
    #
    # Ref: https://docs.rocketpool.net/guides/node/local/prepare-pc#configuring-swappiness-and-cache-pressure
    "vm.swappiness" = 6;
    "vm.vfs_cache_pressure" = 10;
  };
}
