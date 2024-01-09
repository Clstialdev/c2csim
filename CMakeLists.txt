cmake_minimum_required(VERSION 3.16)

set(BASE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")

project(sumotest VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Svg)

qt_standard_project_setup()

qt_add_executable(appsumotest
    main.cpp
)

qt_add_qml_module(appsumotest
    URI sumotest
    VERSION 1.0
    QML_FILES Main.qml
    SOURCES headers/SumoInterface.h
    SOURCES SumoInterface.cpp
    SOURCES geoconverter.h geoconverter.cpp
    RESOURCES images/car2.png
    RESOURCES images/car.svg
    RESOURCES images/car-cropped.svg
    RESOURCES images/car.png
    RESOURCES fonts/fa.otf
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appsumotest PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appsumotest
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)


# Add the directory where the sumo-integrator library is located
include_directories("${BASE_PATH}/sumo-integrator-master/include")
include_directories("${BASE_PATH}/sumo-integrator-master/")

# Link the sumo-integrator library
link_directories("${BASE_PATH}/sumo-integrator-master/bin")


target_link_libraries(appsumotest
    PRIVATE Qt6::Quick Qt6::QuickControls2
    PRIVATE Qt6::Svg
    PRIVATE "${BASE_PATH}/sumo-integrator-master/bin/libsumointegrator.a"
    PRIVATE "${BASE_PATH}/sumo-integrator-master/lib/sumo/libsumo.a"
)

include(GNUInstallDirs)
install(TARGETS appsumotest
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

add_custom_target(run
    COMMAND sumo-gui --remote-port 6066 -c "./sumofiles/osm.sumocfg"
    DEPENDS appsumotest
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

add_custom_target(restart
    COMMAND make clean
    COMMAND make
    COMMAND make run
    DEPENDS clean appsumotest run
)
