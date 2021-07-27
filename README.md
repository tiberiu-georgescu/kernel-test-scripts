# Kernel Test Scripts
Some script to help in testing and debugging kernel functionality. Main focus is memory management.

## Setup

To compile the C scripts, run the following inside the repo's main directory:
```
mkdir obj
make
```
To run the performance scripts, you will need to install [Hyperfine](https://github.com/sharkdp/hyperfine).

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
* -t : Terminate only on SIGKILL (Ctrl-C)
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

In order to make this work best, we will use Hyperfine, an open-source performance testing software.
This needs to be set a-priori, so follow the setup instructions on Hyperfine's [GitHub](https://github.com/sharkdp/hyperfine) page.

### Run Performance Test

To run the full performance test, if you are fine with the default parameters, you may just run this, while logged in as root:
```
sudo -i # a priori
. perf_pagemap.sh 2>/tmp/perf_pagemap.log | tee ~/perf_pagemap.csv
```

If not, you may enter the `perf_pagemap.sh` script and make changes in the inner for loops. Study the parameters that can be parsed to `create_page` and `stats_dd_pagemap.sh` by running the help flag on both:
```
./create_page -h
. stats_dd_pagemap.sh -h
```

If you want finer grained control, you may want to make use only of `create_page` and `stats_dd_pagemap`. If so, the default workflow looks like this:
1. In a terminal window, run `./create_pagemap`, alongside any flags you want. Let it run.
2. In a separate terminal window, run `stats_dd_pagemap.sh`, passing it the arguments outputted by `./create_pagemap` (most notably, PID, VADDR & COUNT)
3. Run stats as many times as you want by changing the "iteration" parameter. Provide different BATCH\_SIZE values to compare performance when batching.

## Contact
If you have any questions or suggestions, please contact me at `tiberiu.georgescu@nutanix.com`. Any feedback is appreciated.
