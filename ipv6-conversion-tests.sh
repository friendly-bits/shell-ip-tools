#!/bin/sh

# tests ipv6 addresses expansion and compression

#### Initial setup
export LC_ALL=C
me=$(basename "$0")

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

. "$script_dir/shell-ip-tools.sh" || { printf '%s\n' "$me: Error: Can't source '$script_dir/shell-ip-tools.sh'." >&2; exit 1; }

test_exp_comp_ipv6() {

tests=" \
2001:4567:1212:00b2:0000:0000:0000:0000 2001:4567:1212:b2::
2001:4567:1111:56ff:0000:0000:0000:0000 2001:4567:1111:56ff::
2001:4567:1111:56ff:0000:0000:0000:0001 2001:4567:1111:56ff::1
ff02:0000:0000:0000:0000:0000:0000:0001 ff02::1
ff05:0000:0000:0000:0000:0000:0001:0003 ff05::1:3
ff02:0000:0000:0000:0000:0001:ff00:0001 ff02::1:ff00:1
ff02:0000:0000:0000:0000:0001:ffce:4ee3 ff02::1:ffce:4ee3
fe80:0000:0000:0000:021b:2bff:fece:4ee3 fe80::21b:2bff:fece:4ee3
fd0e:2146:5cf5:4560:0000:0000:0000:0001 fd0e:2146:5cf5:4560::1
2001:0db8:0000:0000:0000:0000:0002:0001 2001:db8::2:1
2001:0db8:0000:0001:0001:0001:0001:0001 2001:db8:0:1:1:1:1:1
2001:0db8:0000:0000:0001:0000:0000:0001 2001:db8::1:0:0:1
2001:0db8:0000:0000:0000:0000:0000:0001 2001:db8::1
0000:0000:0000:0000:0000:0000:0000:0000 ::
0000:0000:0000:0000:0000:0000:0000:0001 ::1
0001:0000:0000:0000:0000:0000:0000:0000 1::
0000:0001:0000:0000:0000:0000:0000:0000 0:1::
0000:0000:0001:0000:0000:0000:0000:0000 0:0:1::
0000:0000:0000:0001:0000:0000:0000:0000 0:0:0:1::
0000:0000:0000:0000:0001:0000:0000:0000 ::1:0:0:0
0000:0000:0000:0000:0000:0001:0000:0000 ::1:0:0
0000:0000:0000:0000:0000:0000:0001:0000 ::1:0
2001:067c:02e8:0025::c100:0b18 2001:67c:2e8:25::c100:b18
2001:067c:02e8:0025:0000:0000:c100:0b18 2001:67c:2e8:25::c100:b18

0000:0000:0000:0000:0000:0000:0001:0000 ::1:0
0000:0000:0000:0000:0000:0001:0000:0000 ::1:0:0
0000:0000:0000:0000:0001:0000:0000:0000 ::1:0:0:0
0000:0000:0000:0001:0000:0000:0000:0000 0:0:0:1::
0000:0000:0001:0000:0000:0000:0000:0000 0:0:1::
0001:0000:0000:0000:0000:0000:0000:0001 1::1
0001:0000:0000:0000:0000:0000:0001:0000 1::1:0
0001:0001:0000:0000:0000:0000:0000:0000 1:1::
0000:0000:0001:0000:0001:0000:0000:0000 0:0:1:0:1::
0000:0001:0000:0001:0000:0000:0000:0000 0:1:0:1::
0001:0000:0000:0001:0000:0000:0000:0000 1:0:0:1::
0001:0000:0000:0001:0000:0001:0000:0000 1::1:0:1:0:0

:: ::
::1 ::1
1:: 1::
::1:0 ::1:0
::1:0:0 ::1:0:0
0:0:0:0:0:1:: ::1:0:0
::1:0:0:0 ::1:0:0:0
::1:0:0:0:0 0:0:0:1::
0:0:0:1:: 0:0:0:1::
0:0:1:: 0:0:1::
0:1:: 0:1::
1::1 1::1
1::1:0 1::1:0
1:1:: 1:1::
0:0:1:0:1:: 0:0:1:0:1::
0:1:0:1:: 0:1:0:1::
1:0:0:1:: 1:0:0:1::
1::1:0:1:0:0: 1::1:0:1:0:0


2001:4567:1212:b2:: 2001:4567:1212:b2::
2001:4567:1111:56ff:: 2001:4567:1111:56ff::
2001:4567:1111:56ff::1 2001:4567:1111:56ff::1
ff02::1 ff02::1
ff05::1:3 ff05::1:3
ff02::1:ff00:1 ff02::1:ff00:1
ff02::1:ffce:4ee3 ff02::1:ffce:4ee3
fd0e:2146:5cf5:4560::1 fd0e:2146:5cf5:4560::1
2001:db8::2:1 2001:db8::2:1
2001:db8:0:1:1:1:1:1 2001:db8:0:1:1:1:1:1
2001:db8::1:0:0:1 2001:db8::1:0:0:1
2001:db8::1 2001:db8::1
2001:67c:2e8:25::c100:b18 2001:67c:2e8:25::c100:b18
"

	# remove extra spaces and tabs
	tests="$(printf "%s" "$tests" | awk '{$1=$1};1')"

    printf '%s\n' "$tests" |
    {
        test_status=0
    	tests_done=0
        while read -r line; do
            in_ip="${line%% *}"
            out_ip="${line#* }"

    		if [ -n "$in_ip" ] && [ -n "$out_ip" ]; then
    			printf "%s" "."

    			# convert to hex and back, compare result
    			result="$(printf '%s\n' "$in_ip" | aggregate_subnets inet6)"
    			if [ "${result%/128}" != "$out_ip" ]; then
    				printf '%s\n' "Error with input '$in_ip'. Expected '$out_ip', got '$result'." >&2
        			test_status=1
    			fi

    			tests_done=$((tests_done+1))
    		fi
    	done
        printf '\n%s\n' "Tests done: $tests_done"
        exit $test_status
    }
    return $?
}

test_exp_comp_ipv6
status=$?
[ "$status" = 0 ] && noprob=" No problems detected."
printf '%s\n' "Test status: $status.$noprob"
