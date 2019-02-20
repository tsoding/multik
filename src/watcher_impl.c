#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>

#include <sys/inotify.h>

static int inotifyFd = 0;
static int wd = 0;

CAMLprim value
watcher_init(value filename)
{
    inotifyFd = inotify_init();
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
    return Val_false;
}

CAMLprim value
watcher_free(value unit)
{
    // TODO: watcher_free is not implemented 4HEad
    return Val_unit;
}
