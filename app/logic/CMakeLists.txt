# make the qml files visible on qtcreator
file(GLOB LOGIC_JS_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.js)

add_custom_target(com_ubuntu_music_LOGIC_JSFiles ALL SOURCES ${LOGIC_JS_FILES})
