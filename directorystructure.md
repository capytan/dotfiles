# ディレクトリ構成

以下のディレクトリ構造に従って実装を行ってください：

```
/
├── macos/                        # macOS固有の設定
│   ├── defaults/                 # macOSのデフォルト設定
│   └── scripts/                  # macOS用セットアップスクリプト
├── macos_intel/                  # Intel Mac固有の設定
├── ubuntu/                       # Ubuntu固有の設定
│   └── scripts/                  # Ubuntu用セットアップスクリプト
├── vscode/                       # VSCode関連の設定
│   ├── settings.json            # エディタ設定
│   ├── keybindings.json        # キーバインド設定
│   └── extensions.json         # 拡張機能リスト
├── .cursor/                      # Cursor IDE設定
│   └── rules/                   # Cursor用ルール
├── .git/                         # Gitリポジトリ
├── Brewfile                      # Homebrewパッケージリスト
├── dotfileslink.sh              # シンボリックリンク作成スクリプト
├── init.vim                      # Neovim設定
├── .tmux.conf                    # tmux設定
├── .zshrc                        # Zsh設定
├── .bashrc                       # Bash設定
├── .zprofile                     # Zshプロファイル
├── .bash_profile                 # Bashプロファイル
├── .gitignore                    # Git除外設定
└── README.md                     # プロジェクト説明

```

### 配置ルール
- OS固有の設定 → 対応するOSディレクトリ（`macos/`, `ubuntu/`等）に配置
- セットアップスクリプト → 各OSディレクトリの`scripts/`に配置