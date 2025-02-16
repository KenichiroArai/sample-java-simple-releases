@echo off
rem -*- mode: bat; coding: shift-jis -*-
chcp 932 > nul
setlocal enabledelayedexpansion

rem Gitの文字コード設定
git config --local core.quotepath off
git config --local i18n.logoutputencoding shift-jis
git config --local i18n.commitencoding shift-jis

rem リリース自動化スクリプト
rem ===========================================

if "%~1"=="" (
    echo 使用方法：release.bat [作業ブランチ] [リリースブランチ] [バージョン]
    echo 例：release.bat features/release main 1.0.0
    exit /b 1
)

set WORK_BRANCH=%~1
set RELEASE_BRANCH=%~2
set VERSION=%~3

if not "%VERSION:~0,1%"=="v" (
    set VERSION=v%VERSION%
)

echo リリースプロセスを開始します...
echo 作業ブランチ: %WORK_BRANCH%
echo リリースブランチ: %RELEASE_BRANCH%
echo バージョン: %VERSION%

git fetch
if errorlevel 1 goto error

git checkout %WORK_BRANCH%
if errorlevel 1 goto error

git add .
git commit -m "リリース準備：未コミットの変更を追加" || echo 未コミットの変更なし

call mvn versions:set -DnewVersion=%VERSION:~1%
if errorlevel 1 goto error

git add pom.xml
git commit -m "バージョンを %VERSION:~1% に更新" || echo バージョン変更なし

del pom.xml.versionsBackup

git pull origin %WORK_BRANCH% --rebase
if errorlevel 1 goto error

git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
if %errorlevel% equ 0 (
    echo 作業ブランチとリリースブランチに差分がありません。
    echo プルリクエストをスキップしてタグ作成に進みます。
    goto create_tag
)

echo 変更をプッシュ中...
git push origin %WORK_BRANCH%
if errorlevel 1 goto error

where gh >nul 2>nul
if %errorlevel% equ 0 (
    git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
    if errorlevel 1 (
        echo プルリクエストを作成中...
        gh pr create --base %RELEASE_BRANCH% --head %WORK_BRANCH% --title "リリース%VERSION%" --body "リリース%VERSION%のプルリクエストです。"
        if errorlevel 1 goto error
    ) else (
        echo 変更がないため、プルリクエストをスキップします。
    )
) else (
    echo GitHub CLI がインストールされていません。
    echo 手動でプルリクエストを作成してください。
    pause
)

echo プルリクエストがマージされるまで待機します...
echo マージが完了したら Enter キーを押してください...
pause

:create_tag
git checkout %RELEASE_BRANCH%
if errorlevel 1 goto error

git pull origin %RELEASE_BRANCH%
if errorlevel 1 goto error

git tag -d %VERSION% 2>nul
git push origin :refs/tags/%VERSION% 2>nul
git tag %VERSION%
git push origin %VERSION%
if errorlevel 1 goto error

git pull origin %RELEASE_BRANCH%
if errorlevel 1 goto error

echo リリースプロセスが完了しました。
echo GitHub Actions でリリースが作成されるまでお待ちください。
exit /b 0

:error
echo エラーが発生しました。
exit /b 1
