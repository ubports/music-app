# make the image files visible on qtcreator
file(GLOB IMAGE_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.png *.svg)

add_custom_target(com_ubuntu_music_IMAGEFiles ALL SOURCES ${IMAGE_FILES})
