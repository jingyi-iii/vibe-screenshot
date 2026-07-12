#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QWindow>
#include <QTimer>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QStyle>
#include <QIcon>
#include <QDebug>
#include "screenshotmanager.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icon.png"));
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
    trayIcon->setIcon(QIcon(":/icon.png"));
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
    QTimer::singleShot(200, [&engine, manager, &mainWindow, trayIcon]() {
        const auto &rootObjects = engine.rootObjects();
        if (!rootObjects.isEmpty()) {
            QWindow *window = qobject_cast<QWindow *>(rootObjects.first());
            if (window) {
                mainWindow = window;
                qDebug() << "Main window HWND:" << window->winId();
                manager->registerGlobalHotkeys(window);

                // Notify user when window is minimized to tray
                QObject::connect(window, &QWindow::visibleChanged, [trayIcon, window]() {
                    if (!window->isVisible())
                        trayIcon->showMessage(
                            QStringLiteral("Screenshot Tool"),
                            QStringLiteral("Running in tray. Double-click to show, or use Ctrl+Shift+A / Ctrl+Shift+S."),
                            QSystemTrayIcon::Information, 3000);
                });
            } else {
                qWarning() << "Root object is not a QWindow";
            }
        } else {
            qWarning() << "No root objects found for hotkey registration";
        }
    });

    return app.exec();
}
