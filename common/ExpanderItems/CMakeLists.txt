# make the qml files visible on qtcreator
file(GLOB EXPANDERITEMS_QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml)

add_custom_target(com_ubuntu_music_EXPANDERITEMS_QMLFiles ALL SOURCES ${EXPANDERITEMS_QML_FILES})
