project(com.ubuntu.music)
cmake_minimum_required(VERSION 2.8.9)
find_program(INTLTOOL_MERGE intltool-merge)
find_program(INTLTOOL_EXTRACT intltool-extract)

# Standard install paths
include(GNUInstallDirs)

option(INSTALL_TESTS "Install the tests on make install" on)
option(CLICK_MODE "Installs to a contained location" on)

set(APP_NAME music)
set(DESKTOP_FILE "${PROJECT_NAME}_${APP_NAME}.desktop")
set(URLS_FILE "${PROJECT_NAME}_${APP_NAME}.url-dispatcher")
set(APP_HARDCODE music-app)
set(MAIN_QML app/music-app.qml)
set(ICON_FILE app/images/music-app@30.png)
set(AUTOPILOT_DIR music_app)
set(UBUNTU_MANIFEST_PATH "manifest.json.in" CACHE INTERNAL "Tell QtCreator location and name of the manifest file")

if(CLICK_MODE)
    if(NOT DEFINED BZR_SOURCE)
        set(BZR_SOURCE "lp:${APP_HARDCODE}")
        message("-- Setting BZR_SOURCE to ${BZR_SOURCE}")
    endif(NOT DEFINED BZR_SOURCE)
    set(CMAKE_INSTALL_PREFIX /)
    set(CMAKE_INSTALL_BINDIR /)
    set(DATA_DIR /)
    set(ICON ${ICON_FILE})
    set(EXEC "qmlscene -qt5 ${MAIN_QML} --url=%u -I ./plugins")
    set(DESKTOP_DIR ${DATA_DIR})
    set(URLS_DIR ${DATA_DIR})
    
    if(NOT BZR_REVNO)
        set(BZR_REVNO "latest")
    endif(NOT BZR_REVNO)
    
    configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json apparmor.json
            music-app-content.json DESTINATION ${CMAKE_INSTALL_PREFIX})
else(CLICK_MODE)
    set(DATA_DIR ${CMAKE_INSTALL_DATADIR}/${APP_HARDCODE})
    set(EXEC ${APP_HARDCODE})
    set(ICON ${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/${ICON_FILE})
    configure_file(${APP_HARDCODE}.in
        ${CMAKE_CURRENT_BINARY_DIR}/${APP_HARDCODE})
    install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${APP_HARDCODE}
        DESTINATION ${CMAKE_INSTALL_BINDIR})
    set(DESKTOP_DIR ${CMAKE_INSTALL_DATADIR}/applications)
    set(URLS_DIR ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls)
endif(CLICK_MODE)

file(GLOB_RECURSE I18N_SRC_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/po
     *.qml *.js)
list(APPEND I18N_SRC_FILES ${DESKTOP_FILE}.in.in.h)
list(SORT I18N_SRC_FILES)

message("Found ${I18N_SRC_FILES}")

file(GLOB SRC_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.qml *.js *.png *.js *.json)
install(DIRECTORY app DESTINATION ${DATA_DIR})
install(FILES ${SRC_FILES} ${ICON_FILE} DESTINATION ${DATA_DIR})

configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in)

add_custom_target(${DESKTOP_FILE} ALL
    COMMENT "Merging translations into ${DESKTOP_FILE}"
    COMMAND LC_ALL=C ${INTLTOOL_MERGE} -d -u ${CMAKE_SOURCE_DIR}/po ${DESKTOP_FILE}.in ${DESKTOP_FILE}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
    DESTINATION ${DESKTOP_DIR})

install(FILES ${URLS_FILE} DESTINATION ${URLS_DIR})

# Tests
enable_testing()

add_subdirectory(app)
add_subdirectory(po)
add_subdirectory(tests)

# make the qml files visible on qtcreator
file(GLOB QML_JS_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.qml *.js *.translations *.url-dispatcher *.txt)

add_custom_target(com_ubuntu_music_QMLFiles DEPENDS music-app.qml SOURCES ${QML_JS_FILES})
