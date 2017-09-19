#!/usr/sbin/dtrace -Cs 

#pragma D option quiet

#include "defines.include"

/*
 * RUN: echo "foo" > foo
 * RUN: echo "bar" > bar
 * RUN: sudo dtrace -Cs %s -c 'cp_metaio foo foo2 bar bar2'
 */

/*
 * CHECK: OPEN: "uuid": "[[FOO_UUID:[a-f0-9-]+]]"
 * CHECK: READ: "ret_metaio.mio_uuid": "[[FOO_UUID]]"
 * CHECK: WRITE: "arg_metaio.mio_uuid": "[[FOO_UUID]]"
 * CHECK: OPEN: "uuid": "[[BAR_UUID:[a-f0-9-]+]]"
 * CHECK: READ: "ret_metaio.mio_uuid": "[[BAR_UUID]]"
 * CHECK: WRITE: "arg_metaio.mio_uuid": "[[BAR_UUID]]"
 */

audit::aue_write*:commit
/execname == "cp_metaio" &&
 (ARG_HAS_METAIO(args[1]) || RET_HAS_METAIO(args[1]))/
{
    ar = args[1];
    printf("WRITE: ");
    printf("\"arg_metaio.mio_uuid\":%s,",
        UUID_OR_NULL(ARG_HAS_METAIO, ar_arg_metaio.mio_uuid));
    printf("\n");
}
audit::aue_read*:commit
/execname == "cp_metaio" &&
 (ARG_HAS_METAIO(args[1]) || RET_HAS_METAIO(args[1]))/
{
    ar = args[1];
    printf("READ: ");
    printf("\"ret_metaio.mio_uuid\":%s",
        UUID_OR_NULL(RET_HAS_METAIO, ar_ret_metaio.mio_uuid));
    printf("\n");
}

audit::aue_open_*:commit,audit::aue_openat_*:commit
/ execname == "cp_metaio" /
{
    ar = args[1];
    printf("OPEN: ");
    printf("uuid: %s", UUID_OR_NULL(RET_HAS_OBJUUID1, ar_ret_objuuid1));
    printf("\n");
}
