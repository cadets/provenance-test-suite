#!/usr/sbin/dtrace -wCs

#pragma D option quiet
#pragma D option switchrate=1000hz
#pragma D option dynvarsize=16m
#pragma D option bufsize=64m
#pragma D option strsize=4k

/* FROM security/audit/audit_private.h
 *
 * Arguments in the audit record are initially not defined; flags are set to
 * indicate if they are present so they can be included in the audit log
 * stream only if defined.
 */
#define	ARG_EUID		0x0000000000000001ULL
#define	ARG_RUID		0x0000000000000002ULL
#define	ARG_SUID		0x0000000000000004ULL
#define	ARG_EGID		0x0000000000000008ULL
#define	ARG_RGID		0x0000000000000010ULL
#define	ARG_SGID		0x0000000000000020ULL
#define	ARG_PID			0x0000000000000040ULL
#define	ARG_UID			0x0000000000000080ULL
#define	ARG_AUID		0x0000000000000100ULL
#define	ARG_GID			0x0000000000000200ULL
#define	ARG_FD			0x0000000000000400ULL
#define	ARG_POSIX_IPC_PERM	0x0000000000000800ULL
#define	ARG_FFLAGS		0x0000000000001000ULL
#define	ARG_MODE		0x0000000000002000ULL
#define	ARG_DEV			0x0000000000004000ULL
#define	ARG_ADDR		0x0000000000008000ULL
#define	ARG_LEN			0x0000000000010000ULL
#define	ARG_MASK		0x0000000000020000ULL
#define	ARG_SIGNUM		0x0000000000040000ULL
#define	ARG_LOGIN		0x0000000000080000ULL
#define	ARG_SADDRINET		0x0000000000100000ULL
#define	ARG_SADDRINET6		0x0000000000200000ULL
#define	ARG_SADDRUNIX		0x0000000000400000ULL
#define	ARG_TERMID_ADDR		0x0000000000400000ULL
#define	ARG_UNUSED2		0x0000000001000000ULL
#define	ARG_UPATH1		0x0000000002000000ULL
#define	ARG_UPATH2		0x0000000004000000ULL
#define	ARG_TEXT		0x0000000008000000ULL
#define	ARG_VNODE1		0x0000000010000000ULL
#define	ARG_VNODE2		0x0000000020000000ULL
#define	ARG_SVIPC_CMD		0x0000000040000000ULL
#define	ARG_SVIPC_PERM		0x0000000080000000ULL
#define	ARG_SVIPC_ID		0x0000000100000000ULL
#define	ARG_SVIPC_ADDR		0x0000000200000000ULL
#define	ARG_GROUPSET		0x0000000400000000ULL
#define	ARG_CMD			0x0000000800000000ULL
#define	ARG_SOCKINFO		0x0000001000000000ULL
#define	ARG_ASID		0x0000002000000000ULL
#define	ARG_TERMID		0x0000004000000000ULL
#define	ARG_AUDITON		0x0000008000000000ULL
#define	ARG_VALUE		0x0000010000000000ULL
#define	ARG_AMASK		0x0000020000000000ULL
#define	ARG_CTLNAME		0x0000040000000000ULL
#define	ARG_PROCESS		0x0000080000000000ULL
#define	ARG_MACHPORT1		0x0000100000000000ULL
#define	ARG_MACHPORT2		0x0000200000000000ULL
#define	ARG_EXIT		0x0000400000000000ULL
#define	ARG_IOVECSTR		0x0000800000000000ULL
#define	ARG_ARGV		0x0001000000000000ULL
#define	ARG_ENVV		0x0002000000000000ULL
#define	ARG_ATFD1		0x0004000000000000ULL
#define	ARG_ATFD2		0x0008000000000000ULL
#define	ARG_RIGHTS		0x0010000000000000ULL
#define	ARG_FCNTL_RIGHTS	0x0020000000000000ULL
/* Gap:				0x0040000000000000ULL */
#define	ARG_OBJUUID1		0x0080000000000000ULL
#define	ARG_OBJUUID2		0x0100000000000000ULL
#define	ARG_SVIPC_WHICH		0x0200000000000000ULL
#define	ARG_METAIO		0x0400000000000000ULL
#define	ARG_NONE		0x0000000000000000ULL
#define	ARG_ALL			0xFFFFFFFFFFFFFFFFULL

#define	RET_OBJUUID1		0x0000000000000001ULL
#define	RET_OBJUUID2		0x0000000000000002ULL
#define	RET_MSGID		0x0000000000000004ULL
#define	RET_SVIPC_ID		0x0000000000000008ULL
#define	RET_FD1			0x0000000000000010ULL
#define	RET_FD2			0x0000000000000020ULL
#define	RET_METAIO		0x0000000000000040ULL

#define	ARG_IS_VALID(arg)	(args[1]->ar_valid_arg & (arg))
#define	RET_IS_VALID(ret)	(args[1]->ar_valid_ret & (ret))

/* Convenience macro for printing audit fields */
#define sprint_audit_arg_string(flag, field, name) \
	ARG_IS_VALID(flag)?strjoin( strjoin(strjoin(", \"", #name), "\": \""), strjoin(stringof(args[1]->field),"\"")):""
#define sprint_audit_arg_int(flag, field, name) \
	ARG_IS_VALID(flag)?strjoin( strjoin(strjoin(", \"", #name), "\": "), lltostr(args[1]->field)):""
#define sprint_audit_arg_ugid(flag, field, name) \
	ARG_IS_VALID(flag)?strjoin( strjoin(strjoin(", \"", #name), "\": "), lltostr((int32_t)args[1]->field)):""
#define sprint_audit_arg_uuid(flag, field, name)			\
	ARG_IS_VALID(flag)?strjoin( strjoin(strjoin(", \"", #name), "\": \""), strjoin(uuidtostr((uintptr_t)&args[1]->field),"\"")):""
#define sprint_audit_ret_int(flag, field, name)				\
	RET_IS_VALID(flag)?strjoin( strjoin(strjoin(", \"", #name), "\": "), lltostr(args[1]->field)):""
#define sprint_audit_ret_uuid(flag, field, name)			\
	RET_IS_VALID(flag)?strjoin( strjoin(strjoin(", \"", #name), "\": \""), strjoin(uuidtostr((uintptr_t)&args[1]->field),"\"")):""

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
