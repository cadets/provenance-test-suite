# Running tests

Tests can be built with `make build` and run with `sudo make run_tests`

# Current Tests

test_file_uuids.c - Tests UUIDs reported for files/links/moved files.
test_msgid.c - Sends a message over sockets to generate msgid information

# Expected Results
test_file_uuids.c - Should run with no assertion failures. When traced with test_file_uuids.d, the same UUIDs should be reported in the trace as in the running program.
test_msgid.c - When run with trace_msgid.d, send and recv should have the same msgid.

