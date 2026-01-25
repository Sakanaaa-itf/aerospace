#!/bin/bash

# AeroSpace設定ビルドスクリプト
# 共有設定（aerospace.toml.base）とローカル設定（aerospace.toml.local）を結合して
# 最終的な設定ファイル（aerospace.toml）を生成します

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_CONFIG="$SCRIPT_DIR/aerospace.toml.base"
LOCAL_CONFIG="$SCRIPT_DIR/aerospace.toml.local"
OUTPUT_CONFIG="$SCRIPT_DIR/aerospace.toml"

echo "🚀 AeroSpace設定をビルド中..."

# 基本設定ファイルの存在確認
if [ ! -f "$BASE_CONFIG" ]; then
    echo "❌ エラー: $BASE_CONFIG が見つかりません"
    exit 1
fi

# 出力ファイルを作成（基本設定をコピー）
cat "$BASE_CONFIG" > "$OUTPUT_CONFIG"

# ローカル設定が存在する場合は追加
if [ -f "$LOCAL_CONFIG" ]; then
    echo "📝 ローカル設定を追加: $LOCAL_CONFIG"
    echo "" >> "$OUTPUT_CONFIG"
    cat "$LOCAL_CONFIG" >> "$OUTPUT_CONFIG"
else
    echo "⚠️  警告: $LOCAL_CONFIG が見つかりません（ワークスペース割り当てなしで続行）"
    echo "💡 ヒント: $SCRIPT_DIR/aerospace.toml.local.example を参考に作成してください"
fi

echo "✅ 設定ファイルを生成しました: $OUTPUT_CONFIG"

# AeroSpaceを再読み込み（起動中の場合）
if pgrep -x "AeroSpace" > /dev/null; then
    echo "🔄 AeroSpaceを再読み込み中..."
    aerospace reload-config
    echo "✅ 再読み込みが完了しました"
else
    echo "ℹ️  AeroSpaceは起動していません（次回起動時に新しい設定が適用されます）"
fi

echo ""
echo "🎉 完了！"
