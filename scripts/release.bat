@ECHO off
REM -*- mode: bat; coding: shift-jis -*-
CHCP 932 > nul
SETLOCAL enabledelayedexpansion

REM PowerShellのエンコーディング設定
powershell -command "[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"
powershell -command "$OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"

REM Gitの文字コード設定
git config --local core.quotepath off
git config --local i18n.logoutputencoding shift-jis
git config --local i18n.commitencoding shift-jis

REM リリース自動化スクリプト
REM ===========================================

IF "%~1"=="" (
    ECHO 使用方法：release.bat [作業ブランチ] [リリースブランチ] [バージョン]
    ECHO 例：release.bat features/release main 1.0.0
    EXIT /b 1
)

SET WORK_BRANCH=%~1
SET RELEASE_BRANCH=%~2
SET VERSION=%~3

IF NOT "%VERSION:~0,1%"=="v" (
    SET VERSION=v%VERSION%
)

ECHO リリースプロセスを開始します...
ECHO 作業ブランチ: %WORK_BRANCH%
ECHO リリースブランチ: %RELEASE_BRANCH%
ECHO バージョン: %VERSION%

git fetch
IF errorlevel 1 GOTO error

git checkout %WORK_BRANCH%
IF errorlevel 1 GOTO error

git add .
git commit -m "リリース準備：未コミットの変更を追加" || ECHO 未コミットの変更なし

CALL mvn versions:set -DnewVersion=%VERSION:~1%
IF errorlevel 1 GOTO error

git add pom.xml
git commit -m "バージョンを %VERSION:~1% に更新" || ECHO バージョン変更なし

DEL pom.xml.versionsBackup

git pull origin %WORK_BRANCH% --rebase
IF errorlevel 1 GOTO error

git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
IF %errorlevel% equ 0 (
    ECHO 作業ブランチとリリースブランチに差分がありません。
    ECHO プルリクエストをスキップしてタグ作成に進みます。
    GOTO create_tag
)

ECHO 変更をプッシュ中...
git push origin %WORK_BRANCH%
IF errorlevel 1 GOTO error

WHERE gh >nul 2>nul
IF %errorlevel% equ 0 (
    git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
    IF errorlevel 1 (
        ECHO プルリクエストを作成中...
        gh pr create --base %RELEASE_BRANCH% --head %WORK_BRANCH% --title "リリース%VERSION%" --body "リリース%VERSION%のプルリクエストです。"
        IF errorlevel 1 GOTO error
    ) ELSE (
        ECHO 変更がないため、プルリクエストをスキップします。
    )
) ELSE (
    ECHO GitHub CLI がインストールされていません。
    ECHO 手動でプルリクエストを作成してください。
    PAUSE
)

ECHO プルリクエストがマージされるまで待機します...
ECHO マージが完了したら Enter キーを押してください...
PAUSE

:create_tag
git checkout %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

git pull origin %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

git tag -d %VERSION% 2>nul
git push origin :refs/tags/%VERSION% 2>nul
git tag %VERSION%
git push origin %VERSION%
IF errorlevel 1 GOTO error

git pull origin %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

ECHO リリースプロセスが完了しました。
ECHO GitHub Actions でリリースが作成されるまでお待ちください。
EXIT /b 0

:error
ECHO エラーが発生しました。
EXIT /b 1
