add_subdirectory(ListItemActions)

# make the qml files visible on qtcreator
file(GLOB COMMON_QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml)

add_custom_target(com_ubuntu_music_COMMON_QMLFiles ALL SOURCES ${COMMON_QML_FILES})
