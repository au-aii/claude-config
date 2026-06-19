#!/bin/bash
# Claude Code Notification Hook — 入力待ち時に Windows トースト通知を表示する

TIMESTAMP=$(date +%H:%M:%S)
PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")

powershell.exe -Command "
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
    \$template = '<toast><visual><binding template=\"ToastText02\"><text id=\"1\">⏳ ${PROJECT_NAME}</text><text id=\"2\">入力を待っています ($TIMESTAMP)</text></binding></visual><audio silent=\"true\"/></toast>'
    \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    \$xml.LoadXml(\$template)
    \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
"

powershell.exe -c '(New-Object Media.SoundPlayer "C:\Windows\Media\Windows Ding.wav").PlaySync()'
