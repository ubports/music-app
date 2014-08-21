if(CLICK_MODE)
    if(NOT BZR_REVNO)
        set(BZR_REVNO "latest")
    endif(NOT BZR_REVNO)
    configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json apparmor.json
            music-app-content.json DESTINATION ${CMAKE_INSTALL_PREFIX})
endif(CLICK_MODE)

# make the click files visible on qtcreator
file(GLOB CLICK_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.json *.json.in)

add_custom_target(com_ubuntu_music_CLICKFiles ALL SOURCES ${CLICK_FILES})
