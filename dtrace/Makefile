build:
	cc -O0 test_file_uuids.c -o test_file_uuids
	cc -O0 test_msgid.c -o test_msgid

run_tests: build
	dtrace -s test_file_uuids.d -C -c ./test_file_uuids
	dtrace -s test_msgid.d -C -c ./test_msgid

clean:
	rm test_file_uuids
	rm test_msgid
