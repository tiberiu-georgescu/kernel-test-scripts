# Kernel Test Scripts
Some script to help in testing and debugging kernel functionality. Main focus is memory management.

### `create_page()`
Given certain flags, will allocate pages with those
specific characteristics, then return the first page's virtual address
and the own program's PID.

Possible Flags:
* -c <NUM>: Allocate <NUM> ammount of pages
* -p : Make the pages private
* -s : Make the pages shared
* -a : Allocate anonymous pages
* -m : Allocate pages using memfd()
* -f <FILE_NAME> : Allocate pages from existing file

### `create_write_page_twice()`

Does pretty much the same thing as `create_page()`, only it writes again to
the allocated pages. This is useful when testing the `SOFT_DIRTY` bit in
the pagemap.

## Performance Measurement of Pagemap using DD & Hyperfine

The scripts that become useful for this particular task are the following:
* `stats_dd_pagemap.sh`  <- Runs dd n amount of times, given the arguments of a `create_page` process running in the background
* `perf_pagemap.sh`      <- Runs a full performance test, given a suite of arguments, on `create_page`, measuring the performance of retrieving info from Pagemap by using DD
* `reset_test_cgroup.sh` <- Sets and Resets a cgroup on the system

In order to make this work best, we will use Hyperfine, an open-source performance testing software. Can be found on this link: https://github.com/sharkdp/hyperfine .
This needs to be set a-priori, so follow the setup instructions on Hyperfine's GitHub page.
