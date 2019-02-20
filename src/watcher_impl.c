#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>

#include <sys/inotify.h>
#include <limits.h>

#define BUF_LEN (10 * (sizeof(struct inotify_event) + NAME_MAX + 1))

static int inotifyFd = 0;
static int wd = 0;
static char buf[BUF_LEN] __attribute__ ((aligned(8)));

CAMLprim value
watcher_init(value filename)
{
    inotifyFd = inotify_init1(IN_NONBLOCK);
    if (inotifyFd == -1) {
        caml_failwith("Could not initialize inotify system");
    }

    wd = inotify_add_watch(inotifyFd, String_val(filename), IN_CLOSE_WRITE);
    if (wd == -1) {
        // TODO: print the filename we failed to add the watcher too
        caml_failwith("Could not add watcher for a file");
    }

    return Val_unit;
}

CAMLprim value
watcher_is_file_modified(value unit)
{
    ssize_t numRead = read(inotifyFd, buf, BUF_LEN);
    return Val_bool(numRead > 0);
}

CAMLprim value
watcher_free(value unit)
{
    // TODO: watcher_free is not implemented 4HEad
    return Val_unit;
}