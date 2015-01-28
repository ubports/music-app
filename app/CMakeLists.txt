add_subdirectory(common)
add_subdirectory(images)

# make the qml files visible on qtcreator
file(GLOB APP_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
*.qml *.js *.png *.js *.json)

add_custom_target(com_ubuntu_music_APP_Files ALL SOURCES ${APP_FILES})
