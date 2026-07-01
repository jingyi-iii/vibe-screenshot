#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QWindow>
#include <QTimer>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QStyle>
#include <QPainter>
#include <QPixmap>
#include <QDebug>
#include "screenshotmanager.h"

// Create app icon programmatically (multiple sizes for taskbar)
static QIcon createAppIcon()
{
    QIcon icon;
    for (int s : {16, 24, 32, 48, 64}) {
        QPixmap pix(s, s);
        pix.fill(Qt::transparent);
        QPainter p(&pix);
        p.setRenderHint(QPainter::Antialiasing);
        // Background rounded rect
        p.setBrush(QColor("#4a90d9"));
        p.setPen(Qt::NoPen);
        int m = s / 8;
        p.drawRoundedRect(m, m, s - m*2, s - m*2, s/5.0, s/5.0);
        // Camera lens circle
        int r = s / 5;
        p.setBrush(QColor("#ffffff"));
        p.drawEllipse(QPointF(s*0.55, s*0.45), r, r);
        // Camera body
        p.setBrush(QColor("#ffffff"));
        p.drawRoundedRect(s*0.3, s*0.3, s*0.35, s*0.35, r/2, r/2);
        p.end();
        icon.addPixmap(pix);
    }
    return icon;
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setWindowIcon(createAppIcon());
    app.setQuitOnLastWindowClosed(false);

    QQmlApplicationEngine engine;

    // Create ScreenshotManager and expose to QML
    ScreenshotManager *manager = new ScreenshotManager(&app);
    engine.rootContext()->setContextProperty("screenshotManager", manager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("vibe.screenshot", "Main");

    // Create system tray icon
    QSystemTrayIcon *trayIcon = new QSystemTrayIcon(&app);
    trayIcon->setIcon(createAppIcon());
    trayIcon->setToolTip(QStringLiteral("Screenshot Tool\nCtrl+Shift+A: Region\nCtrl+Shift+S: Full Screen"));

    QMenu *trayMenu = new QMenu();
    QAction *showAction = trayMenu->addAction(QStringLiteral("Show"));
    trayMenu->addSeparator();
    QAction *exitAction = trayMenu->addAction(QStringLiteral("Exit"));
    trayIcon->setContextMenu(trayMenu);
    trayIcon->show();

    // Tray menu actions
    QWindow *mainWindow = nullptr;
    QObject::connect(showAction, &QAction::triggered, [&mainWindow]() {
        if (mainWindow) {
            mainWindow->show();
            mainWindow->raise();
            mainWindow->requestActivate();
        }
    });
    QObject::connect(exitAction, &QAction::triggered, [&app]() {
        QApplication::closeAllWindows();  // close all preview windows
        QApplication::processEvents();    // let them finish closing
        app.quit();
    });
    QObject::connect(trayIcon, &QSystemTrayIcon::activated, [&mainWindow](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::DoubleClick && mainWindow) {
            mainWindow->show();
            mainWindow->raise();
            mainWindow->requestActivate();
        }
    });

    // Register global hotkeys after the window is fully created
    // Use a short delay to ensure the native window handle is ready
    QTimer::singleShot(200, [&engine, manager, &mainWindow]() {
        const auto &rootObjects = engine.rootObjects();
        if (!rootObjects.isEmpty()) {
            QWindow *window = qobject_cast<QWindow *>(rootObjects.first());
            if (window) {
                mainWindow = window;
                qDebug() << "Main window HWND:" << window->winId();
                manager->registerGlobalHotkeys(window);
            } else {
                qWarning() << "Root object is not a QWindow";
            }
        } else {
            qWarning() << "No root objects found for hotkey registration";
        }
    });

    return app.exec();
}
