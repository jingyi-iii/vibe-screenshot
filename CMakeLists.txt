cmake_minimum_required(VERSION 3.16)

project(vibe_screenshot VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Static Qt 6.11.1 (bundled in project) ─────────────────────────
# ALWAYS prefer the bundled static Qt — ignores Qt Creator Kit overrides.
set(_qt_vendor_dir "${CMAKE_CURRENT_LIST_DIR}/vendor/Qt/6.11.1-static")
set(_qt_system_dir "C:/Qt/6.11.1-static")

if(EXISTS "${_qt_vendor_dir}")
    set(CMAKE_PREFIX_PATH "${_qt_vendor_dir}" CACHE PATH "Static Qt prefix" FORCE)
    message(STATUS "Using bundled static Qt: ${_qt_vendor_dir}")
elseif(EXISTS "${_qt_system_dir}")
    set(CMAKE_PREFIX_PATH "${_qt_system_dir}" CACHE PATH "Static Qt prefix" FORCE)
    message(STATUS "Using system static Qt: ${_qt_system_dir}")
else()
    message(STATUS "No static Qt found, falling back to: ${CMAKE_PREFIX_PATH}")
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

# ── Auto-generate app.ico from icon.png (PNG → ICO multi-resolution) ──
find_package(Python3 QUIET)
if(Python3_FOUND)
    set(ICON_GEN_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/scripts/generate_icon_from_png.py")
    add_custom_command(
        OUTPUT "${CMAKE_CURRENT_LIST_DIR}/app.ico"
        COMMAND Python3::Interpreter "${ICON_GEN_SCRIPT}"
               "${CMAKE_CURRENT_LIST_DIR}/icon.png"
               "${CMAKE_CURRENT_LIST_DIR}/app.ico"
        DEPENDS "${CMAKE_CURRENT_LIST_DIR}/icon.png" "${ICON_GEN_SCRIPT}"
        COMMENT "Generating app.ico from icon.png"
    )
    add_custom_target(generate_icon ALL
        DEPENDS "${CMAKE_CURRENT_LIST_DIR}/app.ico"
    )
    # Ensure app.rc is recompiled when app.ico changes
    set_source_files_properties(
        "${CMAKE_CURRENT_LIST_DIR}/app.rc"
        PROPERTIES OBJECT_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/app.ico"
    )
endif()

qt_add_executable(vibe_screenshot
    main.cpp
    screenshotmanager.cpp
    screenshotmanager.h
    app.rc
)

qt_add_resources(vibe_screenshot "app_icons"
    PREFIX "/"
    FILES icon.png
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
    # Static runtime + strip debug symbols + dead code elimination
    target_link_options(vibe_screenshot PRIVATE
        -static-libgcc -static-libstdc++ -static
        $<$<CONFIG:Release>:-s>
        $<$<CONFIG:Release>:-Wl,--gc-sections>
    )
    # Compiler: enable function/data sections for gc-sections to work
    target_compile_options(vibe_screenshot PRIVATE
        $<$<CONFIG:Release>:-ffunction-sections>
        $<$<CONFIG:Release>:-fdata-sections>
    )
endif()

install(TARGETS vibe_screenshot
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
