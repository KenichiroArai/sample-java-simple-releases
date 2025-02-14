@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM パラメータのチェック
if "%~1"=="" (
    echo 使用方法：release.bat [作業ブランチ] [リリースブランチ] [バージョン]
    echo 例：release.bat features/release main 1.0.0
    exit /b 1
)

set WORK_BRANCH=%~1
set RELEASE_BRANCH=%~2
set VERSION=%~3

REM バージョン文字列の検証
if not "%VERSION:~0,1%"=="v" (
    set VERSION=v%VERSION%
)

echo リリースプロセスを開始します...
echo 作業ブランチ: %WORK_BRANCH%
echo リリースブランチ: %RELEASE_BRANCH%
echo バージョン: %VERSION%

REM リモートの最新情報を取得
git fetch
if errorlevel 1 goto error

REM 作業ブランチに切り替え
git checkout %WORK_BRANCH%
if errorlevel 1 goto error

REM 未コミットの変更をすべてコミット
git add .
git commit -m "リリース準備：未コミットの変更を追加" || echo 未コミットの変更なし

REM Mavenのバージョンを設定
call mvn versions:set -DnewVersion=%VERSION:~1%
if errorlevel 1 goto error

REM バージョン変更をコミット
git add pom.xml
git commit -m "バージョンを%VERSION:~1%に更新" || echo バージョン変更なし

REM バックアップファイルを削除
del pom.xml.versionsBackup

REM リモートの変更を取り込む
git pull origin %WORK_BRANCH% --rebase
if errorlevel 1 goto error

REM ブランチ間の差分をチェック
git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
if %errorlevel% equ 0 (
    echo 作業ブランチとリリースブランチに差分がありません。
    echo プルリクエストをスキップしてタグ作成に進みます。
    goto create_tag
)

echo 変更をプッシュ中...
git push origin %WORK_BRANCH%
if errorlevel 1 goto error

REM プルリクエストの作成（ghコマンドがある場合）
where gh >nul 2>nul
if %errorlevel% equ 0 (
    REM 変更があるか確認
    git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
    if errorlevel 1 (
        echo プルリクエストを作成中...
        gh pr create --base %RELEASE_BRANCH% --head %WORK_BRANCH% --title "リリース%VERSION%" --body "リリース%VERSION%のプルリクエストです。"
        if errorlevel 1 goto error
    ) else (
        echo 変更がないため、プルリクエストをスキップします。
    )
) else (
    echo GitHub CLIがインストールされていません。
    echo 手動でプルリクエストを作成してください。
    pause
)

REM プルリクエストのマージを待機
echo プルリクエストがマージされるまで待機します...
echo マージが完了したらEnterキーを押してください...
pause

:create_tag
REM リリースブランチに切り替え
git checkout %RELEASE_BRANCH%
if errorlevel 1 goto error

REM 最新の変更を取得
git pull origin %RELEASE_BRANCH%
if errorlevel 1 goto error

REM タグの作成とプッシュ
git tag %VERSION%
git push origin %VERSION%
if errorlevel 1 goto error

echo リリースプロセスが完了しました。
echo GitHub Actionsでリリースが作成されるまでお待ちください。
goto :eof

:error
echo エラーが発生しました。
exit /b 1
