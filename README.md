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

### `create_write_page_twice()`

Does pretty much the same thing as `create_page()`, only it writes again to
the allocated pages. This is useful when testing the `SOFT_DIRTY` bit in
the pagemap.
