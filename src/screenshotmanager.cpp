#include "screenshotmanager.h"

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#include <QScreen>
#include <QGuiApplication>
#include <QWindow>
#include <QClipboard>
#include <QFileDialog>
#include <QDir>
#include <QDateTime>
#include <QStandardPaths>
#include <QPixmap>
#include <QFile>
#include <QTimer>
#include <QCursor>
#include <cstdio>

// Crash-proof logging
#define LOG(msg) do { fprintf(stderr, "[C++] %s\n", msg); fflush(stderr); } while(0)
#define LOG1(msg, arg) do { fprintf(stderr, "[C++] " msg "\n", arg); fflush(stderr); } while(0)

ScreenshotManager::ScreenshotManager(QObject *parent) : QObject(parent)
{
    LOG("ctor");

    // Pre-create AND pre-START a polling timer at construction.
    // The timer runs continuously, checking m_pendingHotkey every 50ms.
    // nativeEventFilter just sets the flag — ZERO Qt calls.
    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(50);
    m_pollTimer->setSingleShot(false);
    connect(m_pollTimer, &QTimer::timeout, this, &ScreenshotManager::processPendingHotkey);
    m_pollTimer->start();
    LOG("  poll timer started (50ms interval)");
}

ScreenshotManager::~ScreenshotManager()
{
    LOG("dtor");
    unregisterGlobalHotkeys();
}

// Called by the pre-created timer from the event loop — safely outside WM_HOTKEY context
void ScreenshotManager::processPendingHotkey()
{
    if (!m_pendingHotkey) return;
    m_pendingHotkey = false;
    int id = m_pendingHotkeyId;
    LOG1("processPendingHotkey: id=%d", id);
    if (id == HOTKEY_REGION_ID) {
        LOG("  -> startRegionCapture");
        startRegionCapture();
    } else if (id == HOTKEY_FULLSCREEN_ID) {
        LOG("  -> captureFullScreen");
        captureFullScreen();
    }
}

void ScreenshotManager::registerGlobalHotkeys(QWindow *window)
{
#ifdef Q_OS_WIN
    if (m_hotkeysRegistered || !window) { LOG("registerHotkeys: skip"); return; }
    m_hotkeyWindow = window;
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    LOG1("registerHotkeys: HWND=%p", hwnd);

    BOOL rA = RegisterHotKey(hwnd, HOTKEY_REGION_ID, MOD_CONTROL | MOD_SHIFT, 'A');
    LOG1("  Ctrl+Shift+A result=%d", rA);
    if (!rA) LOG1("  err=%lu", GetLastError());

    BOOL rS = RegisterHotKey(hwnd, HOTKEY_FULLSCREEN_ID, MOD_CONTROL | MOD_SHIFT, 'S');
    LOG1("  Ctrl+Shift+S result=%d", rS);
    if (!rS) LOG1("  err=%lu", GetLastError());

    m_hotkeysRegistered = true;
    qApp->installNativeEventFilter(this);
    LOG("registerHotkeys: done, filter installed");
#else
    Q_UNUSED(window);
#endif
}

void ScreenshotManager::unregisterGlobalHotkeys()
{
#ifdef Q_OS_WIN
    if (!m_hotkeysRegistered || !m_hotkeyWindow) return;
    HWND hwnd = reinterpret_cast<HWND>(m_hotkeyWindow->winId());
    UnregisterHotKey(hwnd, HOTKEY_REGION_ID);
    UnregisterHotKey(hwnd, HOTKEY_FULLSCREEN_ID);
    m_hotkeysRegistered = false;
    m_hotkeyWindow = nullptr;
    qApp->removeNativeEventFilter(this);
#endif
}

bool ScreenshotManager::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result)
{
#ifdef Q_OS_WIN
    if (eventType == "windows_generic_MSG" || eventType == "windows_dispatcher_MSG") {
        MSG *msg = static_cast<MSG *>(message);
        if (msg->message == WM_HOTKEY) {
            // Set flag only — no logging, no result manipulation, no return true.
            // Let Qt process the message normally after us.
            m_pendingHotkey = true;
            m_pendingHotkeyId = static_cast<int>(msg->wParam);
        }
    }
#else
    Q_UNUSED(eventType); Q_UNUSED(message); Q_UNUSED(result);
#endif
    return false;
}

void ScreenshotManager::startRegionCapture()
{
    LOG("startRegionCapture: enter");
    if (m_capturing) { LOG("  already capturing, force-cancel first"); cancelRegionCapture(); }
    m_capturing = true;
    emit isCapturingChanged();
    LOG("  emitting regionCaptureStarted");
    emit regionCaptureStarted();
    LOG("startRegionCapture: done");
}

void ScreenshotManager::cancelRegionCapture()
{
    if (!m_capturing) return;
    m_capturing = false;
    emit isCapturingChanged();
    emit regionCaptureCancelled();
}

void ScreenshotManager::captureRegion(int x, int y, int w, int h)
{
    fprintf(stderr, "[C++] captureRegion: x=%d y=%d w=%d h=%d\n", x, y, w, h); fflush(stderr);
    m_capturing = false;
    if (w <= 0 || h <= 0) { LOG("  invalid size, return"); return; }
    emit isCapturingChanged();

    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen) { LOG("  no primary screen!"); return; }
    LOG("  calling grabWindow...");
    QPixmap pixmap = screen->grabWindow(0, x, y, w, h);
    LOG1("  pixmap: %dx%d", pixmap.width());
    QImage image = pixmap.toImage();
    if (image.isNull()) { LOG("  image is null!"); return; }
    LOG("  saving...");
    QString path = saveImage(image);
    if (!path.isEmpty()) {
        fprintf(stderr, "[C++]   emitting regionCaptured: %s at %d,%d\n", qPrintable(path), x, y); fflush(stderr);
        emit regionCaptured(path, x, y);
    }
}

void ScreenshotManager::captureFullScreen()
{
    LOG("captureFullScreen: enter");
    LOG("  emitting fullScreenCaptureStarting");
    emit fullScreenCaptureStarting();
    LOG("  starting 100ms timer for grab");
    QTimer::singleShot(100, this, &ScreenshotManager::doCaptureFullScreen);
    LOG("captureFullScreen: done");
}

void ScreenshotManager::doCaptureFullScreen()
{
    LOG("doCaptureFullScreen: enter");
    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen) { LOG("  no primary screen!"); return; }
    LOG1("  screen: %dx%d", screen->size().width());
    LOG("  calling grabWindow(0)...");
    QPixmap pixmap = screen->grabWindow(0);
    LOG1("  pixmap: %dx%d", pixmap.width());
    QImage image = pixmap.toImage();
    if (image.isNull()) { LOG("  image is null!"); return; }
    LOG("  saving...");
    QString path = saveImage(image);
    if (!path.isEmpty()) {
        LOG1("  emitting fullScreenCaptured: %s", qPrintable(path));
        emit fullScreenCaptured(path);
        LOG("  signal emitted OK");
    }
    LOG("doCaptureFullScreen: done");
}

QString ScreenshotManager::saveImage(const QImage &image)
{
    LOG1("saveImage: size=%dx%d", image.size().width());
    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    LOG1("  tempDir: %s", qPrintable(tempDir));
    QString fn = QString("screenshot_%1.png")
        .arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss_zzz"));
    QString fp = QDir(tempDir).absoluteFilePath(fn);
    LOG1("  path: %s", qPrintable(fp));
    bool ok = image.save(fp, "PNG");
    LOG1("  save result: %d", ok);
    return ok ? fp : QString();
}

void ScreenshotManager::copyImageToClipboard(const QString &path)
{
    QImage img(path);
    if (!img.isNull()) QGuiApplication::clipboard()->setImage(img);
}

void ScreenshotManager::deletePreview(const QString &path)
{
    QFile::remove(path);
}

QString ScreenshotManager::saveImageToFile(const QString &src)
{
    QString dst = QFileDialog::getSaveFileName(nullptr, "Save Screenshot",
        QDir::homePath() + "/screenshot.png",
        "PNG (*.png);;JPEG (*.jpg);;BMP (*.bmp)");
    if (dst.isEmpty()) return {};
    QImage img(src);
    return (!img.isNull() && img.save(dst)) ? dst : QString();
}

QPointF ScreenshotManager::cursorGlobalPos()
{
    return QCursor::pos();
}
