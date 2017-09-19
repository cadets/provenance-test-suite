#!/usr/sbin/dtrace -wCs

#pragma D option quiet
#pragma D option switchrate=1000hz
#pragma D option dynvarsize=16m
#pragma D option bufsize=64m
#pragma D option strsize=4k

#include "defines.include"

/*
 * RUN: cc -O0 test_file_uuids.c -o test_file_uuids
 * RUN: sudo dtrace -Cs %s -c '%S/test_file_uuids'
 */

/*
 * CHECK: Original UUID: [[ORIGID:[a-f0-9-]+]]
 * CHECK: New UUID: [[NEWID:[a-f0-9-]+]]
 * CHECK: WRITE: .* [[ORIGID]]
 * CHECK: OPEN: .* [[ORIGID]].*hl.bin
 * CHECK: OPEN: .* [[ORIGID]].*sl.bin
 * CHECK: RENAME: .* [[ORIGID]]
 * CHECK: OPEN: .* [[ORIGID]].*new.bin
 * CHECK: WRITE: .* [[NEWID]]
 * CHECK: OPEN: .* [[NEWID]].*sl.bin
 */
audit::aue_rename*:commit
/ pid == $target /
{
    printf("RENAME: %s\n", 
        sprint_audit_arg_uuid(ARG_OBJUUID1, ar_arg_objuuid1, arg_objuuid1));
}
audit::aue_*read:commit,audit::aue_readl:commit,
audit::aue_*readv:commit,audit::aue_readvl:commit
/ pid == $target /
{
    printf("READ: %s", 
        sprint_audit_arg_uuid(ARG_OBJUUID1, ar_arg_objuuid1, arg_objuuid1));
    printf("%s\n",
    (ARG_IS_VALID(ARG_FD))?strjoin(", \"fdpath\": \"", strjoin(fds[args[1]->ar_arg_fd].fi_pathname, "\"")):"");
}
audit::aue_write:commit,audit::aue_pwrite:commit,audit::aue_writev:commit,audit::aue_writel:commit,audit::aue_writevl:commit
/ pid == $target /
{
    printf("WRITE: %s", 
        sprint_audit_arg_uuid(ARG_OBJUUID1, ar_arg_objuuid1, arg_objuuid1));
    printf("%s\n",
    (ARG_IS_VALID(ARG_FD))?strjoin(", \"fdpath\": \"", strjoin(fds[args[1]->ar_arg_fd].fi_pathname, "\"")):"");
}

audit::aue_open_*:commit,audit::aue_openat_*:commit
/ pid == $target /
{
    printf("OPEN: %s", 
        sprint_audit_arg_uuid(ARG_OBJUUID1, ar_arg_objuuid1, arg_objuuid1));
    printf("%s\n",
    sprint_audit_arg_string(ARG_UPATH1, ar_arg_upath1, upath1));
}
