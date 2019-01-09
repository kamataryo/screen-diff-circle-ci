#!/bin/bash

set -eu

# 引数チェック
if [ $# -eq 1 ]; then
  COMMIT_A=master
  COMMIT_B=$1
elif [ $# -eq 2 ]; then
  COMMIT_A=$1
  COMMIT_B=$2
else
  echo '引数の数が不正です' >&2
  exit 1
fi

if [ ! -f './package.json' ]; then
  echo 'package.jsonが見つかりません。プロジェクトルートでスクリプトを実行してください。' >&2
  exit 2
fi

echo $COMMIT_A..$COMMIT_B

# pc, tb, spから選べる。これは./screenshot.jsに依存

TYPE=tb
TARGET=$TYPE.png

# 現在のディレクトリを保存
CURRENT=$(pwd)
# 結果保存フォルダ
if [ ! -d $CURRENT/screenshots ]; then mkdir $CURRENT/screenshots ; fi
if [ ! -d $CURRENT/screenshots/diff ]; then mkdir $CURRENT/screenshots/diff ; fi
RESULT=$CURRENT/screenshots/diff

# 一時ディレクトリを生成して作業する
TEMP_DIR=$(mktemp -d)

mkdir $TEMP_DIR/project
mkdir $TEMP_DIR/artifacts
mkdir $TEMP_DIR/artifacts/before
mkdir $TEMP_DIR/artifacts/after
mkdir $TEMP_DIR/artifacts/diff

PROJECT=$TEMP_DIR/project/es-stickyboard
TEMP_BEFORE=$TEMP_DIR/artifacts/before/$TARGET
TEMP_AFTER=$TEMP_DIR/artifacts/after/$TARGET
TEMP_DIFF=$TEMP_DIR/artifacts/diff/$TARGET

echo "作業フォルダ:"$TEMP_DIR
echo 'プロジェクトを複製しています..'
rsync -a $CURRENT $TEMP_DIR/project

cd $PROJECT

echo $COMMIT_A'にロールバックしています..'
git stash
git checkout $COMMIT_A
yarn
npm run build

echo 'スクリーンショットを作成しています..'
npm run screenshot
cp -r $PROJECT/screenshots/$TARGET $TEMP_BEFORE

git stash
echo $COMMIT_A'に'$COMMIT_B'をマージしています..(リモートやローカルのリポジトリには反映されません)'
git merge $COMMIT_B
LABEL_A=$COMMIT_A
LABEL_B=$COMMIT_A" <- "$COMMIT_B

yarn
npm run build

echo 'スクリーンショットを作成しています..'
npm run screenshot
cp -r $PROJECT/screenshots/$TARGET $TEMP_AFTER

cd $CURRENT

echo '差分を計算しています..'
# 差分画像を生成
composite -compose difference $TEMP_BEFORE $TEMP_AFTER $TEMP_DIFF

cp $TEMP_DIFF   $RESULT/diff.png
cp $TEMP_BEFORE $RESULT/before.png
cp $TEMP_AFTER  $RESULT/after.png

# 画素平均値の算出・シリアライズ
PIXEL_DIFF=$(identify -format '%[mean]' $TEMP_DIFF)
echo "{\"tb\":$PIXEL_DIFF}" > $RESULT/mean.json
echo '画素平均値:'$PIXEL_DIFF

echo 'レポート画像を生成しています...'
# 枠と文字をつける
convert $TEMP_BEFORE -bordercolor '#777' -border 2x2 -gravity North -splice 0x60 -pointsize 40 -annotate 0x0 "$LABEL_A"         $TEMP_BEFORE
convert $TEMP_AFTER  -bordercolor '#777' -border 2x2 -gravity North -splice 0x60 -pointsize 40 -annotate 0x0 "$LABEL_B"         $TEMP_AFTER
convert $TEMP_DIFF   -bordercolor '#777' -border 2x2 -gravity North -splice 0x60 -pointsize 40 -annotate 0x0 "Diff=$PIXEL_DIFF" $TEMP_DIFF

# 連結
convert +append $TEMP_BEFORE $TEMP_AFTER $TEMP_DIFF $RESULT/summary.png

# clean up
rm -rf $TEMP_DIR
exit 0
