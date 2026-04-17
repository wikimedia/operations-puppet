#!/bin/bash
# SPDX-License-Identifier: CC-BY-SA-4.0
#
# This script is by Brian Pursley https://github.com/brianpursley/kubectl-wait-job
#
# This code is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License.
# To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/
#
# Attribution: This code was inspired by an answer on Stack Overflow licensed under CC BY-SA 4.0.
# Original answer: https://stackoverflow.com/a/60286538/5074828 by Sebastian N (https://stackoverflow.com/users/3745474/sebastian-n)
#

# Check if --help is specified in the arguments and diusplay help text
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        echo "Usage: kubectl wait-job [ARGS] [OPTIONS]"
        echo ""
        echo "This plugin waits for a Kubernetes job to either complete or fail."
        echo ""
        echo "Arguments:"
        echo "  [kubectl args]  Any args will be passed to kubectl wait."
        echo ""
        echo "Options:"
        echo "  [kubectl options]  Any options will be passed to kubectl wait."
        echo ""
        echo "Example:"
        echo "  kubectl wait-job job-name"
        echo ""
        exit 0
    fi
done

# Make sure there is no --for flag
for arg in "$@"; do
    if [[ "$arg" == "--for" || "$arg" == --for=* ]]; then
        echo "Error: The '--for' flag cannot be used with this plugin."
        exit 2
    fi
done

# Cleanup
cleanup() {
    if [[ -n $COMPLETE_STDERR ]]; then
        rm -f "$COMPLETE_STDERR" 2> /dev/null
    fi
    if [[ -n $FAILED_STDERR ]]; then
        rm -f "$FAILED_STDERR" 2> /dev/null
    fi
    if [[ -n $COMPLETE_PID ]]; then
        kill "$COMPLETE_PID" 2> /dev/null
    fi
    if [[ -n $FAILED_PID ]]; then
        kill "$FAILED_PID" 2> /dev/null
    fi
}
trap cleanup EXIT

# Create temporary files to store stderr output
COMPLETE_STDERR=$(mktemp -t kubectl-wait-job-stderr.XXXXXXXXXX) || { echo "error: failed to create temp file"; exit 3; }
FAILED_STDERR=$(mktemp -t kubectl-wait-job-stderr.XXXXXXXXXX) || { echo "error: failed to create temp file"; exit 3; }

# Wait for complete and failed conditions in parallel
kubectl wait job "$@" --for=condition=complete > /dev/null 2> "$COMPLETE_STDERR" &
COMPLETE_PID=$!
kubectl wait job "$@" --for=condition=failed > /dev/null 2> "$FAILED_STDERR" &
FAILED_PID=$!

# Wait for one of the processes to exit (using loop instead of wait -n for compatibility)
while true; do
    # Check if the process waiting for the job to complete has exited
    unset COMPLETE_RESULT
    if ! kill -0 "$COMPLETE_PID" 2>/dev/null; then
        wait $COMPLETE_PID;
        COMPLETE_RESULT=$?
        if [[ $COMPLETE_RESULT -eq 0 ]]; then
            echo "Job completed successfully"
            exit 0
        fi
    fi

    # Check if the process waiting for the job to fail has exited
    unset FAILED_RESULT
    if ! kill -0 "$FAILED_PID" 2>/dev/null; then
        wait $FAILED_PID
        FAILED_RESULT=$?
        if [[ $FAILED_RESULT -eq 0 ]]; then
            echo "Job failed"
            exit 1
        fi
    fi

    # If either process failed, print the stderr output and exit
    if [[ -n $COMPLETE_RESULT || -n $FAILED_RESULT ]]; then
        cat "$COMPLETE_STDERR" 2> /dev/null
        cat "$FAILED_STDERR" 2> /dev/null
        echo "error: kubectl wait failed"
        exit 3
    fi

    # Sleep for a short time before checking again
    sleep 0.1
done
