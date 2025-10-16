#!/bin/bash

# Claude Code コマンドの初期セットアップスクリプト（Mac用）

set -e  # エラーが発生したら即座に終了

# 色付き出力用の変数
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# パスの定義
CLAUDE_DIR="$HOME/.claude"
COMMANDS_LINK="$CLAUDE_DIR/commands"
SETTINGS_LINK="$CLAUDE_DIR/settings.json"
DOTFILES_CLAUDE="$HOME/dotfiles/configs/claude"
DOTFILES_COMMANDS="$DOTFILES_CLAUDE/commands"
DOTFILES_SETTINGS="$DOTFILES_CLAUDE/settings.json"

echo -e "${GREEN}Claude Code コマンドのセットアップを開始します...${NC}"

# シンボリックリンク作成用の関数
create_symlink() {
    local LINK_PATH=$1
    local TARGET_PATH=$2
    local LINK_NAME=$3

    if [ -e "$LINK_PATH" ]; then
        if [ -L "$LINK_PATH" ]; then
            # シンボリックリンクの場合
            CURRENT_TARGET=$(readlink "$LINK_PATH")
            if [ "$CURRENT_TARGET" = "$TARGET_PATH" ]; then
                echo -e "${GREEN}✓ $LINK_NAME は既に正しく設定されています${NC}"
                return 0
            else
                echo -e "${YELLOW}既存の $LINK_NAME シンボリックリンクを削除しています...${NC}"
                rm "$LINK_PATH"
            fi
        else
            # 実際のディレクトリまたはファイルの場合
            echo -e "${RED}警告: $LINK_PATH が既に存在します（シンボリックリンクではありません）。${NC}"
            echo "バックアップを作成してから続行します。"
            BACKUP_NAME="${LINK_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$LINK_PATH" "$BACKUP_NAME"
            echo -e "${YELLOW}バックアップ先: $BACKUP_NAME${NC}"
        fi
    fi

    # シンボリックリンクを作成
    echo -e "${YELLOW}$LINK_NAME のシンボリックリンクを作成しています...${NC}"
    ln -s "$TARGET_PATH" "$LINK_PATH"
    echo -e "${GREEN}✓ $LINK_NAME を設定しました${NC}"
    echo -e "${GREEN}  $LINK_PATH -> $TARGET_PATH${NC}"
}

# 1. dotfiles のファイルが存在するか確認
if [ ! -d "$DOTFILES_COMMANDS" ]; then
    echo -e "${RED}エラー: $DOTFILES_COMMANDS が見つかりません。${NC}"
    echo "dotfiles が正しくクローンされているか確認してください。"
    exit 1
fi

if [ ! -f "$DOTFILES_SETTINGS" ]; then
    echo -e "${RED}エラー: $DOTFILES_SETTINGS が見つかりません。${NC}"
    echo "dotfiles が正しくクローンされているか確認してください。"
    exit 1
fi

# 2. 必要なディレクトリを作成
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}.claude ディレクトリを作成しています...${NC}"
    mkdir -p "$CLAUDE_DIR"
fi

# 3. シンボリックリンクを作成
create_symlink "$COMMANDS_LINK" "$DOTFILES_COMMANDS" "commands"
create_symlink "$SETTINGS_LINK" "$DOTFILES_SETTINGS" "settings.json"

# 4. 確認と完了メッセージ
echo
echo -e "${GREEN}✓ セットアップが完了しました！${NC}"
echo -e "${GREEN}Claude Code でカスタムコマンドと設定が使用できるようになりました。${NC}"
