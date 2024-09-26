// SPDX-FileCopyrightText: 2023 UnionTech Software Technology Co., Ltd.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.deepin.dtk
import Qt.labs.platform
import QtQuick.Controls
import VNote 1.0

ApplicationWindow {
    id: rootWindow

    property int createFolderBtnHeight: 40
    property int leftViewWidth: 200
    property int tmpLeftAreaWidth: 200
    property int tmpWebViewWidth: 0
    property int tmprightDragX: 0
    property int windowMiniHeight: 300
    property int windowMiniWidth: 680

    function toggleTwoColumnMode() {
        if (leftBgArea.visible === false) {
            leftBgArea.visible = true;
            leftDragHandle.visible = true;
            showLeftArea.start();
        } else {
            hideLeftArea.start();
        }
    }

    DWindow.alphaBufferSize: 8
    DWindow.enabled: true
    flags: Qt.Window | Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    height: 680
    minimumHeight: windowMiniHeight
    minimumWidth: windowMiniWidth
    visible: true
    width: 1070

    Component.onCompleted: {
        x = Screen.width / 2 - width / 2;
        y = Screen.height / 2 - height / 2;
    }
    onWidthChanged: {
        if (width < 820) {
            var rigthX = tmprightDragX - (820 - width);
            if (rigthX < 260 || tmprightDragX < rigthX)
                return;
            rightDragHandle.x = rigthX;
            var newWidth = rightDragHandle.x - middeleBgArea.x;
            if (newWidth >= 130 && newWidth <= 200) {
                middeleBgArea.Layout.preferredWidth = newWidth;
            } else {
                leftBgArea.Layout.preferredWidth = rightDragHandle.x - leftDragHandle.width - middeleBgArea.width;
                tmpLeftAreaWidth = leftBgArea.Layout.preferredWidth;
            }
            rightBgArea.Layout.preferredWidth = rowLayout.width - middeleBgArea.width - rightDragHandle.width;
        }
    }

    Shortcuts {
        id: shortcuts

        enabled: rootWindow.active

        onCreateFolder: {
            VNoteMainManager.vNoteCreateFolder();
        }
        onCreateNote: {
            VNoteMainManager.createNote();
        }
        onRenameFolder: {
            folderListView.renameCurrentItem();
        }
        onRenameNote: {
            itemListView.renameCurrentItem();
        }
        onShowShortCutView: {
            VNoteMainManager.preViewShortcut(Qt.point(rootWindow.x + rootWindow.width / 2, rootWindow.y + rootWindow.height / 2));
        }
        onStartRecording: {
            webEngineView.startRecording();
        }
    }

    Connections {
        function handleFinishedFolderLoad(foldersData) {
            for (var i = 0; i < foldersData.length; i++) {
                folderListView.model.append({
                        name: foldersData[i].name,
                        count: foldersData[i].notesCount,
                        icon: foldersData[i].icon
                    });
            }
        }

        function handleUpdateNoteList(notesData) {
            itemListView.model.clear();
            if (notesData.length === 0) {
                webEngineView.webVisible = false;
            } else {
                webEngineView.webVisible = true;
            }
            for (var i = 0; i < notesData.length; i++) {
                var itemIsTop = notesData[i].isTop ? "top" : "normal";
                itemListView.model.append({
                        name: notesData[i].name,
                        time: notesData[i].time,
                        isTop: itemIsTop,
                        icon: notesData[i].icon,
                        folderName: notesData[i].folderName,
                        noteId: notesData[i].noteId
                    });
            }
        }

        function handleaddNote(notesData) {
            itemListView.model.clear();
            var getSelect = -1;
            for (var i = 0; i < notesData.length; i++) {
                var itemIsTop = notesData[i].isTop ? "top" : "normal";
                itemListView.model.append({
                        name: notesData[i].name,
                        time: notesData[i].time,
                        isTop: itemIsTop,
                        icon: notesData[i].icon,
                        folderName: notesData[i].folderName,
                        noteId: notesData[i].noteId
                    });
                if (getSelect === -1 && !notesData[i].isTop)
                    getSelect = i;
            }
            itemListView.selectedNoteItem = [getSelect];
            itemListView.selectSize = 1;
            folderListView.addNote(1);
            itemListView.forceActiveFocus();
        }

        target: VNoteMainManager

        onAddNoteAtHead: {
            handleaddNote(notesData);
        }
        onFinishedFolderLoad: {
            if (foldersData.length > 0) {
                initRect.visible = false;
            }
            initiaInterface.loadFinished(foldersData.length > 0);
            handleFinishedFolderLoad(foldersData);
            itemListView.selectedNoteItem = [0];
            itemListView.selectSize = 1;
        }
        onMoveFinished: {
            folderListView.model.get(srcFolderIndex).count = (Number(folderListView.model.get(srcFolderIndex).count) - index.length).toString();
            folderListView.model.get(dstFolderIndex).count = (Number(folderListView.model.get(dstFolderIndex).count) + index.length).toString();
            var minIndex = itemListView.selectedNoteItem[0];
            for (var i = 0; i < itemListView.selectedNoteItem.length; i++) {
                if (itemListView.selectedNoteItem[i] < minIndex)
                    minIndex = itemListView.selectedNoteItem[i];
                itemListView.model.remove(itemListView.selectedNoteItem[i]);
            }
            itemListView.selectedNoteItem = [];
            if (Number(folderListView.model.get(srcFolderIndex).count) === 0) {
                webEngineView.webVisible = false;
            } else {
                webEngineView.webVisible = true;
            }
            if (!itemListView.view.itemAtIndex(minIndex)) {
                minIndex = itemListView.model.count - 1;
            }
            itemListView.selectedNoteItem.push(minIndex);
            itemListView.view.itemAtIndex(minIndex).isSelected = true;
            itemListView.selectSize = 1;
            VNoteMainManager.vNoteChanged(itemListView.model.get(minIndex).noteId);
        }
        onNoSearchResult: {
            label.visible = false;
            folderListView.opacity = 0.4;
            folderListView.enabled = false;
            createFolderButton.enabled = false;
            webEngineView.webVisible = false;
            webEngineView.noSearchResult = true;
        }
        onSearchFinished: {
            label.visible = false;
            folderListView.opacity = 0.4;
            folderListView.enabled = false;
            createFolderButton.enabled = false;
        }
        onUpdateNotes: {
            handleUpdateNoteList(notesData);
            itemListView.selectedNoteItem = [selectIndex];
            itemListView.selectSize = 1;
        }
    }

    IconLabel {
        id: appImage

        height: 30
        icon.height: 20
        icon.name: "deepin-voice-note"
        icon.width: 20
        width: 30
        x: 10
        y: 10
        z: 100
    }

    ToolButton {
        id: twoColumnModeBtn

        height: 30
        icon.height: 30
        icon.name: "topleft"
        icon.width: 30
        width: 30
        x: 50
        y: 10
        z: 100

        onClicked: {
            toggleTwoColumnMode();
        }
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: leftBgArea

            Layout.fillHeight: true//#F2F6F8
            Layout.preferredWidth: leftViewWidth
            color: DTK.themeType === ApplicationHelper.LightType ? "#EBF6FF" : "#101010"

            ColumnLayout {
                anchors.bottomMargin: 10
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 5
                anchors.topMargin: 50

                FolderListView {
                    id: folderListView

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    onEmptyItemList: isEmpty => {
                        webEngineView.webVisible = !isEmpty;
                    }
                    onFolderEmpty: {
                        initRect.visible = true;
                        initiaInterface.loadFinished(false);
                    }
                    onItemChanged: {
                        label.text = name;
                        itemListView.selectedNoteItem = [0];
                        itemListView.selectSize = 1;
                        VNoteMainManager.vNoteFloderChanged(index);
                    }
                    onUpdateFolderName: {
                        label.text = name;
                    }
                }

                Button {
                    id: createFolderButton

                    Layout.fillWidth: true
                    Layout.preferredHeight: createFolderBtnHeight
                    text: qsTr("Create Notebook")

                    onClicked: {
                        folderListView.addFolder();
                    }
                }
            }

            Connections {
                target: itemListView

                onDeleteNotes: {
                    folderListView.delNote(number);
                }
                onDropRelease: {
                    var indexList = [];
                    for (var i = 0; i < itemListView.selectedNoteItem.length; i++) {
                        indexList.push(itemListView.model.get(itemListView.selectedNoteItem[i]).noteId);
                    }
                    folderListView.dropItems(indexList);
                }
                onMouseChanged: {
                    folderListView.updateItems(mousePosX, mousePosY);
                }
                onMulChoices: {
                    webEngineView.toggleMultCho(choices);
                }
            }
        }

        Rectangle {
            id: leftDragHandle

            Layout.fillHeight: true
            Layout.preferredWidth: 5
            color: leftBgArea.color

            Rectangle {
                anchors.right: parent.right
                color: DTK.themeType === ApplicationHelper.LightType ? "#eee7e7e7" : "#ee252525"
                height: parent.height
                width: 1
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.axis: Drag.XAxis
                drag.maximumX: 200
                drag.minimumX: 130
                drag.target: leftDragHandle

                onPositionChanged: {
                    if (drag.active) {
                        var newWidth = leftDragHandle.x;
                        if (newWidth >= 130 && newWidth <= 200) {
                            leftBgArea.Layout.preferredWidth = newWidth;
                            tmpLeftAreaWidth = newWidth;
                            rightBgArea.Layout.preferredWidth = rowLayout.width - leftBgArea.width - leftDragHandle.width;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: middeleBgArea

            Layout.fillHeight: true
            Layout.preferredWidth: leftViewWidth
            color: DTK.themeType === ApplicationHelper.LightType ? "#F1F5F8" : "#D9000000"

            ColumnLayout {
                Layout.topMargin: 7
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 5
                spacing: 10

                SearchEdit {
                    id: search

                    property int offect: 0

                    function exitSearch() {
                        folderListView.toggleSearch(false);
                        search.focus = false;
                        if (itemListView.searchLoader.active) {
                            itemListView.searchLoader.item.visible = false;
                        }
                        itemListView.view.visible = true;
                        label.visible = true;
                        folderListView.opacity = 1;
                        folderListView.enabled = true;
                        createFolderButton.enabled = true;
                        itemListView.isSearch = false;
                        webEngineView.webVisible = true;
                        webEngineView.noSearchResult = false;
                        VNoteMainManager.clearSearch();
                    }

                    Layout.fillWidth: true
                    Layout.leftMargin: offect
                    Layout.preferredHeight: 30
                    Layout.topMargin: 12
                    placeholder: qsTr("Search")

                    Keys.onPressed: {
                        if (text.length === 0)
                            return;
                        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                            VNoteMainManager.vNoteSearch(text);
                        }
                    }
                    onTextChanged: {
                        if (text.length === 0)
                            exitSearch();
                    }

                    Connections {
                        function onClicked(mouse) {
                            search.exitSearch();
                        }

                        target: search.clearButton.item
                    }
                }

                Label {
                    id: label

                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    Layout.topMargin: 5
                    color: DTK.themeType === ApplicationHelper.LightType ? "#BB000000" : "#BBFFFFFF"
                    font.pixelSize: 16
                    text: ""
                }

                ItemListView {
                    id: itemListView

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    moveToFolderDialog.folderModel: folderListView.model

                    onNoteItemChanged: {
                        VNoteMainManager.vNoteChanged(index);
                    }
                }
            }
        }

        Rectangle {
            id: rightDragHandle

            Layout.fillHeight: true
            Layout.preferredWidth: 5
            color: middeleBgArea.color

            Component.onCompleted: {
                tmprightDragX = rightDragHandle.x;
            }

            MouseArea {
                id: rightMouseArea

                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.axis: Drag.XAxis
                drag.maximumX: 400
                drag.minimumX: 260
                drag.target: rightDragHandle

                onPositionChanged: {
                    if (drag.active) {
                        tmprightDragX = rightDragHandle.x;
                        var newWidth = rightDragHandle.x - middeleBgArea.x;
                        if (newWidth >= 130 && newWidth <= 200) {
                            middeleBgArea.Layout.preferredWidth = newWidth;
                        } else {
                            leftBgArea.Layout.preferredWidth = rightDragHandle.x - leftDragHandle.width - middeleBgArea.width;
                            tmpLeftAreaWidth = leftBgArea.Layout.preferredWidth;
                        }
                        rightBgArea.Layout.preferredWidth = rowLayout.width - middeleBgArea.width - rightDragHandle.width;
                    }
                }
            }
        }

        Rectangle {
            id: rightBgArea

            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Qt.rgba(0, 0, 0, 0.01)

            BoxShadow {
                anchors.fill: rightBgArea
                cornerRadius: rightBgArea.radius
                hollow: true
                shadowBlur: 10
                shadowColor: Qt.rgba(0, 0, 0, 0.05)
                shadowOffsetX: 0
                shadowOffsetY: 4
                spread: 0
            }

            ColumnLayout {
                anchors.fill: parent

                WebEngineView {
                    id: webEngineView

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    onDeleteNote: {
                        itemListView.onDeleteNote();
                    }
                    onMoveNote: {
                        itemListView.onMoveNote();
                    }
                    onSaveAudio: {
                        itemListView.onSaveAudio();
                    }
                    onSaveNote: {
                        itemListView.onSaveNote();
                    }
                }
            }
        }
    }

    Rectangle {
        id: initRect

        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent

            InitialInterface {
                id: initiaInterface

                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }

        Connections {
            target: initiaInterface

            onCreateFolder: {
                folderListView.addFolder();
                initRect.visible = false;
            }
        }
    }

    ParallelAnimation {
        id: hideLeftArea

        onFinished: {
            leftBgArea.visible = false;
        }
        onStarted: {
            leftDragHandle.visible = false;
            tmpWebViewWidth = rightBgArea.width;
        }

        NumberAnimation {
            duration: 200
            from: leftBgArea.width
            property: "width"
            target: leftBgArea
            to: 0
        }

        NumberAnimation {
            duration: 200
            from: leftBgArea.width + leftDragHandle.width
            property: "x"
            target: middeleBgArea
            to: 0
        }

        NumberAnimation {
            duration: 200
            from: leftBgArea.width + leftDragHandle.width + middeleBgArea.width + rightDragHandle.width
            property: "x"
            target: rightBgArea
            to: middeleBgArea.width + rightDragHandle.width
        }

        NumberAnimation {
            duration: 200
            from: tmpWebViewWidth
            property: "width"
            target: webEngineView
            to: middeleBgArea.width + rightDragHandle.width + tmpWebViewWidth
        }

        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
            from: 0
            property: "offect"
            target: search
            to: 85
        }
    }

    ParallelAnimation {
        id: showLeftArea

        NumberAnimation {
            duration: 200
            from: 0
            property: "width"
            target: leftBgArea
            to: tmpLeftAreaWidth
        }

        NumberAnimation {
            duration: 200
            from: 0
            property: "x"
            target: middeleBgArea
            to: tmpLeftAreaWidth + 5
        }

        NumberAnimation {
            duration: 200
            from: middeleBgArea.width + rightDragHandle.width
            property: "x"
            target: rightBgArea
            to: tmpLeftAreaWidth + 5 + middeleBgArea.width + rightDragHandle.width
        }

        NumberAnimation {
            duration: 200
            from: middeleBgArea.width + rightDragHandle.width + tmpWebViewWidth
            property: "width"
            target: rightBgArea
            to: tmpWebViewWidth
        }

        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
            from: 85
            property: "offect"
            target: search
            to: 0
        }
    }
}
