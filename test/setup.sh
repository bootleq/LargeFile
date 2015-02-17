#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DIR/fixtures"

dd if=/dev/urandom of="$DIR/fixtures/18mb.txt" bs=1048576 count=18
dd if=/dev/urandom of="$DIR/fixtures/19mb.txt" bs=1048576 count=19
