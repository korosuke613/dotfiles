#!/bin/bash

if [ $# -ne 1 ]; then
  echo "指定された引数は$#個です。" 1>&2
  echo "実行するには1個の引数が必要です。" 1>&2
  exit 1
fi

# 作業用ディレクトリの作成・移動
mkdir __work
cd __work

# PDF -> TXT
pdftotext ../$1 ./$1.txt
# 改行の削除
sed -z "s/\n/ /g" ./$1.txt > ./one_liner_$1.txt
# ピリオドの後に改行を挿入
sed "s/\. /\.\n/g" ./one_liner_$1.txt > ./period_new_line_$1.txt
# 行の頭に%(LaTeXのコメントアウト)を挿入
sed "s/^/% /g" ./period_new_line_$1.txt > ../gen_$1.txt

# 作業用ディレクトリの削除
cd ../
rm -rf ./__work
