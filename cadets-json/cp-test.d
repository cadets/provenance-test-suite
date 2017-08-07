
/*
 * RUN: echo "hello" > foo
 * RUN: sudo dtrace -Cs -c 'cp foo bar'
 */

/*
 * CHECK: aue_openat_rwtc:commit [[INPUT_FILE:.*]]
 * CHECK: aue_openat_rwtc:commit [[OUTPUT_FILE:.*]]
 */
audit::aue_*open*:commit
{
	printf("%s", uuidtostr((uintptr_t) &args[1]->ar_ret_objuuid1));
}

/*
 * CHECK: aue_write:commit [[OUTPUT_FILE]]
 */
audit::aue_*read*:commit,
audit::aue_*write*:commit
{
	printf("%s", uuidtostr((uintptr_t) &args[1]->ar_arg_objuuid1));
}
