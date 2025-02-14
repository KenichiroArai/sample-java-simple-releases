# リリースプロセス

このドキュメントでは、GitHub でのリリース作成手順について説明します。

## 前提条件

- GitHub アカウントを持っていること
- リポジトリへのプッシュ権限があること
- ローカル環境に Java 21 と Maven がインストールされていること

## 手順の詳細

### 1. コードの準備

```bash
# リモートの最新情報を取得
git fetch

# ブランチの切り替え（作業用のブランチに切り替える）

git checkout features/release

# 変更状態の確認
git status

# 変更のコミット（未コミットの変更がある場合）
git add .
git commit -m "リリース準備完了"

# 変更のプッシュ
git push origin features/release
```

### 2. バージョンの設定

```bash
# Mavenのバージョンを設定（例：1.0.0）（うまく行かない場合は直接pom.xmlを編集する）
mvn versions:set -DnewVersion=1.0.0

# バージョン変更をコミット
git add pom.xml
git commit -m "バージョンを1.0.0に更新"
git push origin feature/release
```

### 3. プルリクエストによるリリース対象のブランチへマージ

リリースするブランチが保護されて、直接 push 出来ない場合はプルリクエストを作成します。

GitHub の Web サイトから作成または VSCode ・ Cursor からプルリクエストの作成と承認もできます。

```bash
# プルリクエストの作成
gh pr create --base main --head features/release --title "リリース1.0.0" --body "リリース1.0.0のプルリクエストです。"
```

プルリクエストからマージします。

### 4. リリースの作成

```bash
# ブランチの切り替え（リリースをするブランチ）
git checkout main

# プッシュ
git push origin main

# タグの作成（vから始める必要があります）
git tag v1.0.0

# タグのプッシュ
git push origin v1.0.0
```

### 5. リリース確認

1. GitHub のリポジトリページで「Actions」タブを開く
2. ワークフローの実行状況を確認
3. 完了後、「Releases」タブでリリースを確認

## 自動化される処理

タグをプッシュすると、以下の処理が自動的に実行されます：

1. GitHub Actions の起動
2. プロジェクトのビルド
3. JAR ファイルの生成
4. GitHub リリースの作成
5. JAR ファイルのリリースへの添付
6. リリースノートの自動生成

## 注意事項

- タグは必ず`v`から始めること（例：v1.0.0）
- リリース前に全ての変更がメインブランチにプッシュされていることを確認
- `pom.xml`のバージョンとタグのバージョンは一致させることを推奨

## トラブルシューティング

リリース作成に問題が発生した場合：

1. GitHub Actions のログを確認
2. エラーメッセージを確認
3. 必要に応じてタグを削除して再試行：

   ```bash
   # ローカルのタグを削除
   git tag -d v1.0.0
   # リモートのタグを削除
   git push --delete origin v1.0.0
   ```
