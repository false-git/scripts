#!/bin/sh
# $Id$
# カレントディレクトリ以下にあるディレクトリのファイルを、ディレクトリ単位で
# zip にするスクリプト。
# エラーチェック等なにもなし。
#
# ~/.mkzippathにzipの格納ディレクトリを入れておく。
# PATHの通ったところにrenum.plが必要。

DESTDIR=`cat ~/.mkzippath`

mkzip() {
    result=0
    cd "$1"
    for i in *
    do
	if [ -d "$i" ]; then
	    mkzip "$i"
	    result=0
	else
	    renum.pl "$i"
	    result=1
	fi
    done
    if [ $result -eq 1 ]; then
	echo "$1"
	zip "$DESTDIR/$1.zip" *
    fi
    cd ..
}

for i in *
do
    mkzip "$i"
done

