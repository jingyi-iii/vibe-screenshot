#ifndef SCREENSHOTMANAGER_H
#define SCREENSHOTMANAGER_H

#include <QObject>
#include <QImage>
#include <QAbstractNativeEventFilter>

class QWindow;

class ScreenshotManager : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT
    Q_PROPERTY(bool isCapturing READ isCapturing NOTIFY isCapturingChanged)

public:
    explicit ScreenshotManager(QObject *parent = nullptr);
    ~ScreenshotManager();

    bool isCapturing() const { return m_capturing; }

    Q_INVOKABLE void startRegionCapture();
    Q_INVOKABLE void captureFullScreen();
    Q_INVOKABLE void captureRegion(int x, int y, int w, int h);
    Q_INVOKABLE void cancelRegionCapture();
    Q_INVOKABLE void copyImageToClipboard(const QString &imagePath);
    Q_INVOKABLE void deletePreview(const QString &previewId);
    Q_INVOKABLE QString saveImageToFile(const QString &imagePath);
    Q_INVOKABLE QPointF cursorGlobalPos();  // for reliable hover detection

    // Register global hotkeys (Win32)
    void registerGlobalHotkeys(QWindow *window);
    void unregisterGlobalHotkeys();

signals:
    void regionCaptureStarted();
    void regionCaptureCancelled();
    void fullScreenCaptureStarting();
    void fullScreenCaptured(const QString &imagePath);
    void regionCaptured(const QString &imagePath, int rx, int ry);
    void isCapturingChanged();

private slots:
    void doCaptureFullScreen();
    void processPendingHotkey();

protected:
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

private:
    QString saveImage(const QImage &image);

    bool m_capturing = false;
    bool m_hotkeysRegistered = false;
    QWindow *m_hotkeyWindow = nullptr;

    // Deferred hotkey handling: nativeEventFilter ONLY sets a plain bool flag.
    // A pre-started polling QTimer picks it up from the event loop.
    // ZERO Qt calls inside nativeEventFilter — not even QTimer::start().
    bool m_pendingHotkey = false;
    int m_pendingHotkeyId = 0;
    QTimer *m_pollTimer = nullptr;

    static const int HOTKEY_REGION_ID = 1;
    static const int HOTKEY_FULLSCREEN_ID = 2;
};

#endif // SCREENSHOTMANAGER_H
