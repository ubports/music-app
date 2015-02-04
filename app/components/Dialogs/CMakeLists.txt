# make the qml files visible on qtcreator
file(GLOB DIALOGS_QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml)

add_custom_target(com_ubuntu_music_DIALOGS_QMLFiles ALL SOURCES ${DIALOGS_QML_FILES})
