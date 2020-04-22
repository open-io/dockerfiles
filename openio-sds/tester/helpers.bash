#!/bin/bash

# Function which retries an instruction until the max amount of time, with sleep between retries.
# Only the exit code of the instruction is checked.
# Args:
#  - $1: max number of retries
#  - $2: time to wait between retries
#  - $3..: instruction to execute for each retry.
function retry() {
    local counter=0
    local max_retries=$1
    shift
    local wait_time=$1
    shift
    until [ "${counter}" -ge "${max_retries}" ]
    do
        if "$@"
        then
            break
        fi
        sleep "${wait_time}"
        counter=$((counter+1))
    done
    # assert is a Bats primitive
    assert [ "${counter}" -lt "${max_retries}" ]
}

# Function which retries to compare (exactly) an instruction's stdout with a provided value, until the max amount of time, with sleep between retries.
# Args:
#  - $1: max number of retries
#  - $2: time to wait between retries
#  - $3: value to compare instruction with
#  - $4..: instruction to execute for each retry.
function retry_equals() {
    local counter=0
    local max_retries=$1
    shift
    local wait_time=$1
    shift
    local equal_value=$1
    shift
    until [ "${counter}" -ge "${max_retries}" ]
    do
        # assert_equal is a Bats primitive
        if assert_equal "$("$@")" "${equal_value}"
        then
            break
        fi
        sleep "${wait_time}"
        counter=$((counter+1))
    done
    # assert is a Bats primitive
    assert [ "${counter}" -lt "${max_retries}" ]
}

# Function which retries to compare (partially) an instruction's stdout with a provided value, until the max amount of time, with sleep between retries.
# Args:
#  - $1: max number of retries
#  - $2: time to wait between retries
#  - $3: partial value to assert output with
#  - $4..: instruction to execute for each retry.
function retry_contains_output() {
    local counter=0
    local max_retries=$1
    shift
    local wait_time=$1
    shift
    local partial_value=$1
    shift
    until [ "${counter}" -ge "${max_retries}" ]
    do
        # run and assert_output are a Bats-assert primitives
        if run "$@" && assert_output --partial "${partial_value}"
        then
            break
        fi
        sleep "${wait_time}"
        counter=$((counter+1))
    done
    # assert is a Bats primitive
    assert [ "${counter}" -lt "${max_retries}" ]
}

# Function which retries to compare and refute (partially) an instruction's stdout with a provided value, until the max amount of time, with sleep between retries.
# Args:
#  - $1: max number of retries
#  - $2: time to wait between retries
#  - $3: partial value to refute output with
#  - $4..: instruction to execute for each retry.
function retry_refute_output() {
    local counter=0
    local max_retries=$1
    shift
    local wait_time=$1
    shift
    local partial_value=$1
    shift
    until [ "${counter}" -ge "${max_retries}" ]
    do
        # run and assert_output are a Bats-assert primitives
        if run "$@" && refute_output --partial "${partial_value}"
        then
            break
        fi
        sleep "${wait_time}"
        counter=$((counter+1))
    done
    # assert is a Bats primitive
    assert [ "${counter}" -lt "${max_retries}" ]
}
