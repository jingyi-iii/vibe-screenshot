cmake_minimum_required(VERSION 3.16)

project(vibe_screenshot VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Static Qt 6.11.1 (bundled in project) ─────────────────────────
# Priority: 1) command-line -DCMAKE_PREFIX_PATH  2) bundled vendor dir
if(NOT DEFINED CMAKE_PREFIX_PATH)
    set(_qt_vendor_dir "${CMAKE_CURRENT_LIST_DIR}/vendor/Qt/6.11.1-static")
    if(EXISTS "${_qt_vendor_dir}")
        set(CMAKE_PREFIX_PATH "${_qt_vendor_dir}")
    else()
        # Fallback to system path (for CI / older setups)
        set(CMAKE_PREFIX_PATH "C:/Qt/6.11.1-static")
    endif()
endif()

# Request static Qt libraries (no shared libs / DLLs)
set(Qt6_FIND_COMPONENTS_QUIET TRUE)

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Widgets
    Quick QuickControls2
)

qt_standard_project_setup(REQUIRES 6.10)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(vibe_screenshot
    main.cpp
    screenshotmanager.cpp
    screenshotmanager.h
)

qt_add_qml_module(vibe_screenshot
    URI vibe.screenshot
    QML_FILES
        Main.qml
        RegionSelector.qml
        PreviewWindow.qml
)

# ═══ Static QML plugin import (generates the Q_IMPORT_PLUGIN stubs) ═══
qt_import_qml_plugins(vibe_screenshot)

set_target_properties(vibe_screenshot PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.vibe_screenshot
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(vibe_screenshot
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Widgets
        # ── Static platform + image plugins ──
        Qt6::QWindowsIntegrationPlugin
        Qt6::QJpegPlugin
        Qt6::QGifPlugin
        Qt6::QICOPlugin
        Qt6::QSvgPlugin
        Qt6::QSvgIconPlugin
)

# ── Windows system libraries needed by static Qt (MinGW) ──
if(WIN32 AND MINGW)
    target_link_libraries(vibe_screenshot PRIVATE
        ws2_32 opengl32 user32 gdi32 ole32 shell32 imm32
        winmm version dwmapi uxtheme
        d3d11 dxgi dxguid
        setupapi netapi32 mpr winspool
    )
    # Ensure static runtime (-static-libgcc -static-libstdc++ -static)
    target_link_options(vibe_screenshot PRIVATE
        -static-libgcc -static-libstdc++ -static
    )
endif()

install(TARGETS vibe_screenshot
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
