/*
* Copyright (C) 2019 ~ 2020 Uniontech Software Technology Co.,Ltd.
*
* Author:     liuyanga <liuyanga@uniontech.com>
*
* Maintainer: liuyanga <liuyanga@uniontech.com>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef LEFTVIEW_H
#define LEFTVIEW_H

#include <QStandardItemModel>
#include <QDateTime>

#include <DTreeView>
#include <DMenu>
DWIDGET_USE_NAMESPACE

class LeftViewDelegate;
class LeftViewSortFilter;
class FolderSelectDialog;
class MoveView;

struct VNoteFolder;
//记事本列表
class LeftView : public DTreeView
{
    Q_OBJECT
public:
    explicit LeftView(QWidget *parent = nullptr);
    //获取记事本项父节点
    QStandardItem *getNotepadRoot();
    //获取记事本项父节点索引
    QModelIndex getNotepadRootIndex();
    //选中默认记事本项
    QModelIndex setDefaultNotepadItem();
    //清除选中后，恢复选中
    QModelIndex restoreNotepadItem();
    //只有选中项有右键菜单
    void setOnlyCurItemMenuEnable(bool enable);
    //添加记事本
    void addFolder(VNoteFolder *folder);
    //从列表后追加记事本
    void appendFolder(VNoteFolder *folder);
    //记事本项重命名
    void editFolder();
    //记事本排序
    void sort();
    //关闭右键菜单
    void closeMenu();
    //获取记事本个数
    int folderCount();
    //删除选中的记事本
    VNoteFolder *removeFolder();
    //移动笔记
    bool doNoteMove(const QModelIndexList &src, const QModelIndex &dst);
    QModelIndex selectMoveFolder(const QModelIndexList &src);
    //获取记事本顺序
    QString getFolderSort();
    //是否需要更新排序
    bool needFolderSort();
    //处理触摸屏slide事件
    void handleTouchSlideEvent(qint64 timeParam, double distY, QPoint point);

signals:
    void dropNotesEnd();
protected:
    //鼠标事件
    //单击
    void mousePressEvent(QMouseEvent *event) override;
    //单击释放
    void mouseReleaseEvent(QMouseEvent *event) override;
    //双击
    void mouseDoubleClickEvent(QMouseEvent *event) override;
    //移动
    void mouseMoveEvent(QMouseEvent *event) override;
    //按键事件
    void keyPressEvent(QKeyEvent *e) override;
    //关闭重命名编辑框触发
    void closeEditor(QWidget *editor, QAbstractItemDelegate::EndEditHint hint) override;

    void dragEnterEvent(QDragEnterEvent *event) override;
    void dragMoveEvent(QDragMoveEvent *event) override;
    void dragLeaveEvent(QDragLeaveEvent *event) override;
    void dropEvent (QDropEvent * event ) override;
    void startDrag(Qt::DropActions supportedActions) override;


private:
    //初始化代理模块
    void initDelegate();
    //初始化数据管理模块
    void initModel();
    //初始化记事本项父节点
    void initNotepadRoot();
    //初始化右键菜单
    void initMenu();
    //触发拖动操作
    void triggerDragFolder();
    //设置记事本默认顺序
    bool setFolderSort();
    //拖拽移动
    void doDragMove(const QModelIndex &src, const QModelIndex &dst);

    DMenu *m_notepadMenu {nullptr};
    QStandardItemModel *m_pDataModel {nullptr};
    LeftViewDelegate *m_pItemDelegate {nullptr};
    LeftViewSortFilter *m_pSortViewFilter {nullptr};
    bool m_onlyCurItemMenuEnable {false};
    FolderSelectDialog *m_folderSelectDialog {nullptr};
    MoveView *m_MoveView {nullptr};
    bool    m_folderDraing {false};

    //以下为实现触摸屏功能声明参数
    bool m_isTouchSliding {false};
    qint64 m_touchPressStartMs = 0;
    QPoint m_touchPressPoint;
};

#endif // LEFTVIEW_H
