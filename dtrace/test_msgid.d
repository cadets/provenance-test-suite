#!/usr/sbin/dtrace -wCs

#pragma D option quiet
#pragma D option switchrate=1000hz
#pragma D option dynvarsize=16m
#pragma D option bufsize=64m
#pragma D option strsize=4k

#include "defines.include"

/*
 * RUN: cc -O0 test_msgid.c -o test_msgid
 * RUN: sudo dtrace -Cs %s -c '%S/test_msgid'
 */

/*
 * CHECK: SEND: "ret_msgid": [[MSGID:[0-9]+]][[$]]
 * CHECK-NEXT: RECV: "ret_msgid": [[MSGID]][[$]]
 */
audit::aue_recv*:commit
/execname == "test_msgid" /
{
    printf("RECV: %s\n", sprint_audit_ret_int(RET_MSGID, ar_ret_msgid, ret_msgid));
}

audit::aue_send*:commit
/execname == "test_msgid" /
{
    printf("SEND: %s\n", sprint_audit_ret_int(RET_MSGID, ar_ret_msgid, ret_msgid));
}
