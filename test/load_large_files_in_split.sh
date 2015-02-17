#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

cd $DIR
vim -u plugin.rc fixtures/18mb.txt fixtures/19mb.txt +split +bnext
