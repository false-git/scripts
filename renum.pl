#!/usr/bin/env perl
# $Id$
# 与えられたファイルのファイル名が [0-9_-]* の形式でない場合は、
# [0-9_-]*部分だけを残すようにする。

use strict;

$ARGV[0] =~ /^(.*?)([0-9_-]*\.jpg)/;
if ("$1" ne "") {
    rename $ARGV[0], $2;
}
