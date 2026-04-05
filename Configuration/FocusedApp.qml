import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

BasePill {
    id: root

    property var widgetData: null
    property bool compactMode: widgetData?.focusedWindowCompactMode !== undefined ? widgetData.focusedWindowCompactMode : SettingsData.focusedWindowCompactMode
    property int availableWidth: 400
    readonly property int maxNormalWidth: 456
    readonly property int maxCompactWidth: 288
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    property var activeDesktopEntry: null
    property bool isHovered: mouseArea.containsMouse
    property bool isAutoHideBar: false

    readonly property real minTooltipY: {
        if (!parentScreen || !isVerticalOrientation) {
            return 0;
        }

        if (isAutoHideBar) {
            return 0;
        }

        if (parentScreen.y > 0) {
            return barThickness + (barSpacing || 4);
        }

        return 0;
    }

    Component.onCompleted: {
        updateDesktopEntry();
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.updateDesktopEntry();
        }
    }

    Connections {
        target: root
        function onActiveWindowChanged() {
            root.updateDesktopEntry();
        }
    }

    Connections {
        target: SettingsData
        function onAppIdSubstitutionsChanged() {
            root.updateDesktopEntry();
        }
    }

    function updateDesktopEntry() {
        if (activeWindow && activeWindow.appId) {
            const moddedId = Paths.moddedAppId(activeWindow.appId);
            activeDesktopEntry = DesktopEntries.heuristicLookup(moddedId);
        } else {
            activeDesktopEntry = null;
        }
    }
    readonly property bool hasWindowsOnCurrentWorkspace: {
        if (CompositorService.isNiri) {
            let currentWorkspaceId = null;
            for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
                const ws = NiriService.allWorkspaces[i];
                if (ws.is_focused) {
                    currentWorkspaceId = ws.id;
                    break;
                }
            }

            if (!currentWorkspaceId) {
                return false;
            }

            const workspaceWindows = NiriService.windows.filter(w => w.workspace_id === currentWorkspaceId);
            return workspaceWindows.length > 0 && activeWindow && (activeWindow.title || activeWindow.appId);
        }

        if (CompositorService.isHyprland) {
            if (!Hyprland.focusedWorkspace || !activeWindow || !(activeWindow.title || activeWindow.appId)) {
                return false;
            }

            try {
                if (!Hyprland.toplevels)
                    return false;
                const hyprlandToplevels = Array.from(Hyprland.toplevels.values);
                const activeHyprToplevel = hyprlandToplevels.find(t => t?.wayland === activeWindow);

                if (!activeHyprToplevel || !activeHyprToplevel.workspace) {
                    return false;
                }

                return activeHyprToplevel.workspace.id === Hyprland.focusedWorkspace.id;
            } catch (e) {
                return false;
            }
        }

        return activeWindow && (activeWindow.title || activeWindow.appId);
    }

    width: hasWindowsOnCurrentWorkspace ? (isVerticalOrientation ? barThickness : visualWidth) : 0
    height: hasWindowsOnCurrentWorkspace ? (isVerticalOrientation ? visualHeight : barThickness) : 0
    visible: hasWindowsOnCurrentWorkspace

    content: Component {
        Item {
            implicitWidth: {
                if (!root.hasWindowsOnCurrentWorkspace)
                    return 0;
                if (root.isVerticalOrientation)
                    return root.widgetThickness - root.horizontalPadding * 2;
                const baseWidth = contentRow.implicitWidth;
                return compactMode ? Math.min(baseWidth, maxCompactWidth - root.horizontalPadding * 2) : Math.min(baseWidth, maxNormalWidth - root.horizontalPadding * 2);
            }
            implicitHeight: root.widgetThickness - root.horizontalPadding * 2
            clip: false

            IconImage {
                id: appIcon
                anchors.centerIn: parent
                width: 18
                height: 18
                visible: root.isVerticalOrientation && activeWindow && status === Image.Ready
                source: {
                    if (!activeWindow || !activeWindow.appId)
                        return "";
                    return Paths.getAppIcon(activeWindow.appId, activeDesktopEntry);
                }
                smooth: true
                mipmap: true
                asynchronous: true
                layer.enabled: activeWindow && activeWindow.appId === "org.quickshell"
                layer.smooth: true
                layer.mipmap: true
                layer.effect: MultiEffect {
                    saturation: 0
                    colorization: 1
                    colorizationColor: Theme.primary
                }
            }

            DankIcon {
                anchors.centerIn: parent
                size: 18
                name: "sports_esports"
                color: Theme.widgetTextColor
                visible: root.isVerticalOrientation && activeWindow && activeWindow.appId && appIcon.status !== Image.Ready && Paths.isSteamApp(activeWindow.appId)
            }

            Text {
                anchors.centerIn: parent
                visible: root.isVerticalOrientation && activeWindow && activeWindow.appId && appIcon.status !== Image.Ready && !Paths.isSteamApp(activeWindow.appId)
                text: {
                    if (!activeWindow || !activeWindow.appId)
                        return "?";
                    const appName = Paths.getAppName(activeWindow.appId, activeDesktopEntry);
                    return appName.charAt(0).toUpperCase();
                }
                font.pixelSize: 10
                color: Theme.widgetTextColor
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: Theme.spacingS
                visible: !root.isVerticalOrientation
                
                StyledText {
                    id: appText
                    text: {
                        if (!activeWindow || !activeWindow.appId)
                            return "";
                        return Paths.getAppName(activeWindow.appId, activeDesktopEntry);
                    }
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, compactMode ? 80 : 180)
                    visible: !compactMode && text.length > 0
                }

                StyledText {
                    text: "•"
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.outlineButton
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !compactMode && appText.text && titleText.text
                }

                StyledText {
                    id: titleText
                    text: {
                        const title = activeWindow && activeWindow.title ? activeWindow.title : "";
                        const appName = appText.text;

                        if (compactMode) {
                            if (!title || title === appName)
                                return title || appName;
                            if (title.endsWith(appName))
                                return title.substring(0, title.length - appName.length).replace(/ (-|—) $/, "") || appName;
                            return title;
                        }

                        if (!title || !appName)
                            return title;

                        if (title.endsWith(appName))
                            return title.substring(0, title.length - appName.length).replace(/ (-|—) $/, "");

                        return title;
                    }
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, compactMode ? 280 : 250)
                    visible: text.length > 0
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            if (!activeWindow || !root.parentScreen)
                return;

            const currentScreen = root.parentScreen;
            const screenX = currentScreen ? currentScreen.x : 0;
            const screenY = currentScreen ? currentScreen.y : 0;
            const appName = activeWindow.appId ? Paths.getAppName(activeWindow.appId, activeDesktopEntry) : "";
            const title = activeWindow.title || "";
            const tooltipText = appName + (title ? " • " + title : "");

            if (root.isVerticalOrientation && activeWindow.appId) {
                tooltipLoader.active = true;
                if (tooltipLoader.item) {
                    const globalPos = mapToGlobal(width / 2, height / 2);
                    const relativeY = globalPos.y - screenY;
                    const adjustedY = relativeY + root.minTooltipY;
                    const tooltipX = root.axis?.edge === "left"
                        ? (Theme.barHeight + (barConfig?.spacing ?? 4) + Theme.spacingXS)
                        : (currentScreen.width - Theme.barHeight - (barConfig?.spacing ?? 4) - Theme.spacingXS);
                    const isLeft = root.axis?.edge === "left";
                    tooltipLoader.item.show(tooltipText, screenX + tooltipX, adjustedY, currentScreen, isLeft, !isLeft);
                }
            } else if (!root.isVerticalOrientation) {
                hoverTooltipLoader.active = true;
                if (hoverTooltipLoader.item) {
                    const globalPos = mapToGlobal(width / 2, height / 2);
                    const relativeX = globalPos.x - screenX;
                    const isTop = root.axis?.edge !== "bottom";
                    const tooltipY = isTop
                        ? (Theme.barHeight + (barConfig?.spacing ?? 4) + Theme.spacingXS)
                        : (currentScreen.height - Theme.barHeight - (barConfig?.spacing ?? 4) - Theme.spacingXS);
                    hoverTooltipLoader.item.show(tooltipText, relativeX, screenY + tooltipY, currentScreen);
                }
            }
        }
        onExited: {
            if (tooltipLoader.item)
                tooltipLoader.item.hide();
            tooltipLoader.active = false;

            if (hoverTooltipLoader.item)
                hoverTooltipLoader.item.hide();
            hoverTooltipLoader.active = false;
        }
    }

    // Vertical bar: standard DankTooltip
    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: DankTooltip {}
    }

    // Horizontal bar: custom PanelWindow tooltip — same style, no 300px width cap
    Loader {
        id: hoverTooltipLoader
        active: false
        sourceComponent: Component {
            PanelWindow {
                id: hTip

                property string text: ""
                property real targetX: 0
                property real targetY: 0
                property var targetScreen: null

                function show(t, x, y, screen) {
                    text = t;
                    targetScreen = screen;
                    targetX = x;
                    targetY = y;
                    visible = true;
                }
                function hide() {
                    visible = false;
                }

                WlrLayershell.namespace: "dms:tooltip"
                screen: targetScreen
                implicitWidth: hTipText.implicitWidth + Theme.spacingM * 2
                implicitHeight: hTipText.implicitHeight + Theme.spacingS * 2
                color: "transparent"
                visible: false
                WlrLayershell.layer: WlrLayershell.Overlay
                WlrLayershell.exclusiveZone: -1

                anchors {
                    top: true
                    left: true
                }

                margins {
                    left: {
                        const sw = targetScreen?.width ?? Screen.width;
                        return Math.round(Math.max(Theme.spacingS, Math.min(sw - implicitWidth - Theme.spacingS, targetX - implicitWidth / 2)));
                    }
                    top: {
                        const sh = targetScreen?.height ?? Screen.height;
                        return Math.round(Math.max(Theme.spacingS, Math.min(sh - implicitHeight - Theme.spacingS, targetY)));
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    radius: height / 2
                    border.width: 1
                    border.color: Theme.outlineMedium

                    Text {
                        id: hTipText
                        anchors.centerIn: parent
                        text: hTip.text
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        wrapMode: Text.NoWrap
                    }
                }
            }
        }
    }
}


// Path: /usr/share/quickshell/dms/Modules/DankBar/Widgets/FocusedApp.qml
