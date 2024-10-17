// Copyright (C) 2019 ~ 2019 UnionTech Software Technology Co.,Ltd.
// SPDX-FileCopyrightText: 2023 UnionTech Software Technology Co., Ltd.
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include "jscontent.h"

#include <QFile>
#include <QVariant>
#include <QEventLoop>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QClipboard>
#include <QMimeData>
#include <QDateTime>
#include <QImage>
#include <QDebug>
#include <QApplication>

JsContent::JsContent()
{
    connect(QApplication::clipboard(), &QClipboard::changed, this, &JsContent::onClipChange);
}

JsContent *JsContent::instance()
{
    static JsContent _instance;
    return &_instance;
}

/**
 * @brief JsContent::insertImages
 * 判断图片路径是否有效，存在有效路径则创建副本传到web端中
 * @param filePaths 图片路径
 * @return 此次操作是否有效
 */
bool JsContent::insertImages(QStringList filePaths)
{
    int count = 0;
    QStringList paths;
    // 获取文件夹路径
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/images";
    // 创建文件夹
    QDir().mkdir(dirPath);
    // 获取时间戳
    QDateTime currentDateTime = QDateTime::currentDateTime();
    QString date = currentDateTime.toString("yyyyMMddhhmmss");

    for (auto path : filePaths) {
        QFileInfo fileInfo(path);
        QString suffix = fileInfo.suffix();
        if (!(suffix == "jpg" || suffix == "png" || suffix == "bmp")) {
            continue;
        }
        // 创建文件路径
        QString newPath = QString("%1/%2_%3.%4").arg(dirPath).arg(date).arg(++count).arg(suffix);
        if (QFile::copy(path, newPath)) {
            paths.push_back(newPath);
        }
    }
    if (paths.size() == 0) {
        return false;
    }
    emit callJsInsertImages(paths);
    return true;
}

/**
 * @brief JsContent::insertImages
 * 向web端传入图片
 * @param image
 * @return 操作是否成功 true:成功
 */
bool JsContent::insertImages(const QImage &image)
{
    // 获取文件夹路径
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/images";
    // 创建文件夹
    QDir().mkdir(dirPath);
    // 保存文件，文件名为当前年月日时分秒
    QDateTime currentDateTime = QDateTime::currentDateTime();
    QString fileName = currentDateTime.toString("yyyyMMddhhmmss.png");
    QString imgPath = dirPath + "/" + fileName;

    // 保存文件
    if (!image.save(imgPath)) {
        return false;
    }
    emit callJsInsertImages(QStringList(imgPath));
    return true;
}

QString JsContent::webPath()
{
    return "file://" WEB_PATH "/index.html";
}

void JsContent::jsCallTxtChange()
{
    emit textChange();
}

void JsContent::jsCallChannleFinish()
{
    emit getfontinfo();
}

void JsContent::jsCallSummernoteInitFinish()
{
    emit loadFinsh();
}

void JsContent::jsCallPopupMenu(int type, const QVariant &json)
{
    emit popupMenu(type, json);
}

void JsContent::jsCallPlayVoice(const QVariant &json, bool bIsSame)
{
    emit playVoice(json, bIsSame);
}

QString JsContent::jsCallGetTranslation()
{
    static QJsonDocument doc;
    if (doc.isEmpty()) {
        QJsonObject object;
        object.insert("fontname", QApplication::translate("web", "Font"));
        object.insert("fontsize", QApplication::translate("web", "Font size"));
        object.insert("forecolor", QApplication::translate("web", "Font color"));
        object.insert("backcolor", QApplication::translate("web", "Text highlight color"));
        object.insert("bold", QApplication::translate("web", "Bold"));
        object.insert("italic", QApplication::translate("web", "Italic"));
        object.insert("underline", QApplication::translate("web", "Underline"));
        object.insert("strikethrough", QApplication::translate("web", "Strikethrough"));
        object.insert("ul", QApplication::translate("web", "Bullets"));
        object.insert("ol", QApplication::translate("web", "Numbering"));
        object.insert("more", QApplication::translate("web", "More colors"));
        object.insert("recentlyUsed", QApplication::translate("web", "Recent"));
        doc.setObject(object);
    }
    return doc.toJson(QJsonDocument::Compact);
}

/**
   @return Js前端调用返回部分 HTML DOM 节点展示需要的翻译文本
 */
QString JsContent::jsCallDivTextTranslation()
{
    static QJsonDocument doc;
    if (doc.isEmpty()) {
        QJsonObject object;
        object.insert("translateLabel", QApplication::translate("web", "Voice To Text"));
        object.insert("translatingLabel", QApplication::translate("web", "Converting voice to text"));
        doc.setObject(object);
    }
    return doc.toJson(QJsonDocument::Compact);
}

void JsContent::jsCallScrollChange(int scrollTop)
{
    emit scrollTopChange(scrollTop == 0);
}

/**
   @brief Js前端调用停止播放
 */
void JsContent::jsCallPlayVoiceStop()
{
    Q_EMIT playVoiceStop();
}

/**
   @brief 变更播放进度，仅在手动拖拽进度条时触发
   @param progressMs 拖拽后的进度毫秒(ms)值
 */
void JsContent::jsCallVoiceProgressChange(qint64 progressMs)
{
    Q_EMIT playVoiceProgressChange(progressMs);
}

QVariant JsContent::callJsSynchronous(QWebEnginePage *page, const QString &funtion)
{
    QVariant synResult;
    QEventLoop synLoop;
    if (page) {
        page->runJavaScript(funtion, [&](const QVariant &result) {
            synResult = result;
            synLoop.quit();
        });
        synLoop.exec();
    }
    return synResult;
}

void JsContent::jsCallSetDataFinsh()
{
    emit setDataFinsh();
}

void JsContent::jsCallPaste(bool isVoicePaste)
{
    emit textPaste(isVoicePaste);
}

void JsContent::jsCallViewPicture(const QString &imagePath)
{
    emit viewPictrue(imagePath);
}

void JsContent::jsCallCreateNote()
{
    emit createNote();
}

void JsContent::jsCallSetClipData(const QString &text, const QString &html)
{
    QClipboard *clip = QApplication::clipboard();
    if (nullptr != clip) {
        // 剪切板先断开与前端的通信
        clip->disconnect(this);
        // 更新剪切板
        QMimeData *data = new QMimeData;
        // 设置纯文本
        data->setText(text);
        // 设置富文本
        data->setHtml(html);
        clip->setMimeData(data);
        m_clipData = data;
        // 剪切板重新建立与前端的通信
        connect(QApplication::clipboard(), &QClipboard::changed, this, &JsContent::onClipChange);
    }
}

void JsContent::onClipChange(QClipboard::Mode mode)
{
    if (QClipboard::Clipboard == mode && QApplication::clipboard()->mimeData() != m_clipData) {
        emit callJsClipboardDataChanged();
    }
}
