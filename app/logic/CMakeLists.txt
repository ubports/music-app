# make the qml files visible on qtcreator
file(GLOB LOGIC_QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml *.js)

add_custom_target(com_ubuntu_music_LOGIC_QMLFiles ALL SOURCES ${LOGIC_QML_FILES})
