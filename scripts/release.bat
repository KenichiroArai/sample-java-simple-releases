@ECHO off
REM -*- mode: bat; coding: shift-jis -*-

REM ===========================================
REM �����[�X�������X�N���v�g
REM ===========================================
REM
REM �O������F
REM - GitHub �A�J�E���g�������Ă��邱��
REM - ���|�W�g���ւ̃v�b�V�����������邱��
REM - �ȉ����C���X�g�[������Ă��邱�ƁF
REM   - Java 21
REM   - Maven
REM   - Git
REM   - GitHub CLI�i�I�v�V�����F�v�����N�G�X�g�̎����쐬�ɕK�v�j
REM
REM �g�p���@�F
REM   release.bat [��ƃu�����`] [�����[�X�u�����`] [�o�[�W����]
REM   ��Frelease.bat features/release main 1.0.0
REM
REM �@�\�F
REM - �w�肵���o�[�W�����ł̃����[�X�쐬��������
REM - pom.xml �̃o�[�W�����X�V
REM - ���R�~�b�g�̕ύX�̎����R�~�b�g
REM - �����[�g�u�����`�Ƃ̎�������
REM - �v�����N�G�X�g�̍쐬�iGitHub CLI�g�p���j
REM - �^�O�̍쐬�ƃv�b�V��
REM
REM ���ӎ����F
REM - �o�[�W�����ԍ��̐擪�́uv�v�͏ȗ��\�i�����I�ɕt���j
REM - �v�����N�G�X�g�̃}�[�W�͎蓮�ōs���K�v����
REM - GitHub CLI���C���X�g�[�����̓v�����N�G�X�g���蓮�ō쐬
REM - ���̃o�b�`�t�@�C����SJIS�ŃR���\�[���o�͂�ݒ�
REM
REM �t�@�C���`���Ɋւ��钍�ӎ����F
REM - ���̃o�b�`�t�@�C����Shift-JIS�iSJIS�j�ŕۑ�����K�v������܂�
REM - ���s�R�[�h��CRLF�iWindows�`���j���g�p���Ă�������
REM - �t�@�C���擪�� mode: bat; coding: shift-jis �w����폜���Ȃ��ł�������
REM ===========================================

CHCP 932 > nul
SETLOCAL enabledelayedexpansion

REM PowerShell�̃G���R�[�f�B���O�ݒ�
powershell -command "[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"
powershell -command "$OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"

REM �����[�X�������X�N���v�g
REM ===========================================

IF "%~1"=="" (
    ECHO �g�p���@�Frelease.bat [��ƃu�����`] [�����[�X�u�����`] [�o�[�W����]
    ECHO ��Frelease.bat features/release main 1.0.0
    EXIT /b 1
)

SET WORK_BRANCH=%~1
SET RELEASE_BRANCH=%~2
SET VERSION=%~3

IF NOT "%VERSION:~0,1%"=="v" (
    SET VERSION=v%VERSION%
)

ECHO �����[�X�v���Z�X���J�n���܂�...
ECHO ��ƃu�����`: %WORK_BRANCH%
ECHO �����[�X�u�����`: %RELEASE_BRANCH%
ECHO �o�[�W����: %VERSION%

git fetch
IF errorlevel 1 GOTO error

git checkout %WORK_BRANCH%
IF errorlevel 1 GOTO error

git add .
git commit -m "�����[�X�����F���R�~�b�g�̕ύX��ǉ�" || ECHO ���R�~�b�g�̕ύX�Ȃ�

CALL mvn versions:set -DnewVersion=%VERSION:~1%
IF errorlevel 1 GOTO error

git add pom.xml
git commit -m "�o�[�W������ %VERSION:~1% �ɍX�V" || ECHO �o�[�W�����ύX�Ȃ�

DEL pom.xml.versionsBackup

git pull origin %WORK_BRANCH% --rebase
IF errorlevel 1 GOTO error

git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
IF %errorlevel% equ 0 (
    ECHO ��ƃu�����`�ƃ����[�X�u�����`�ɍ���������܂���B
    ECHO �v�����N�G�X�g���X�L�b�v���ă^�O�쐬�ɐi�݂܂��B
    GOTO create_tag
)

ECHO �ύX���v�b�V����...
git push origin %WORK_BRANCH%
IF errorlevel 1 GOTO error

WHERE gh >nul 2>nul
IF %errorlevel% equ 0 (
    git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
    IF errorlevel 1 (
        ECHO �v�����N�G�X�g���쐬��...
        gh pr create --base %RELEASE_BRANCH% --head %WORK_BRANCH% --title "�����[�X%VERSION%" --body "�����[�X%VERSION%�̃v�����N�G�X�g�ł��B"
        IF errorlevel 1 GOTO error
    ) ELSE (
        ECHO �ύX���Ȃ����߁A�v�����N�G�X�g���X�L�b�v���܂��B
    )
) ELSE (
    ECHO GitHub CLI ���C���X�g�[������Ă��܂���B
    ECHO �蓮�Ńv�����N�G�X�g���쐬���Ă��������B
    PAUSE
)

ECHO �v�����N�G�X�g���}�[�W�����܂őҋ@���܂�...
ECHO �}�[�W������������ Enter �L�[�������Ă�������...
PAUSE

:create_tag
REM �����[�X�u�����`�ɐ؂�ւ�
git checkout %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

REM --ff-only�I�v�V������ǉ�����fast-forward�݂̂�����
git pull origin %RELEASE_BRANCH% --ff-only
IF errorlevel 1 (
    ECHO �����[�g�̕ύX���擾�ł��܂���ł����B
    ECHO ���[�J���u�����`���ŐV��Ԃł͂���܂���B
    EXIT /b 1
)

REM �^�O�쐬�O�ɍēx�u�����`�̏�Ԃ��m�F
git status | findstr "Your branch is up to date" > nul
IF errorlevel 1 (
    ECHO �u�����`���ŐV��Ԃł͂���܂���B
    ECHO git pull �����s���čŐV�̕ύX���擾���Ă��������B
    EXIT /b 1
)

git tag -d %VERSION% 2>nul
git push origin :refs/tags/%VERSION% 2>nul
git tag %VERSION%
git push origin %VERSION%
IF errorlevel 1 GOTO error

ECHO �����[�X�v���Z�X���������܂����B
ECHO GitHub Actions �Ń����[�X���쐬�����܂ł��҂����������B
EXIT /b 0

:error
ECHO �G���[���������܂����B
EXIT /b 1
