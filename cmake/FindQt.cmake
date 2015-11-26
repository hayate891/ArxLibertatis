
set(WITH_QT CACHE STRING "The Qt version to use: 4 or 5 or empty (use any)")

unset(HAVE_QT)

set(_Qt_COMPONENTS Core)
foreach(lib IN LISTS Qt_FIND_COMPONENTS)
	if(lib STREQUAL "Widgets")
		list(APPEND _Qt_COMPONENTS Gui)
	endif()
	list(APPEND _Qt_COMPONENTS ${lib})
endforeach()
list(REMOVE_DUPLICATES _Qt_COMPONENTS)

set(_Qt_FIND_ARGS)
if(NOT WITH_QT)
	# If the user has not requested a specific version, don't spam them
	# when either one is not found.
	set(_Qt_Qt5_FIND_ARGS QUIET)
else()
	if(Qt_FIND_QUIETLY)
		list(APPEND _Qt_FIND_ARGS QUIET)
	endif()
	if(Qt4_FIND_REQUIRED)
		list(APPEND _Qt_FIND_ARGS REQUIRED)
	endif()
endif()

# Try to find Qt 5 modules
if(NOT HAVE_QT AND (NOT WITH_QT OR WITH_QT EQUAL 5))
	
	set(HAVE_QT5 1)
	foreach(lib IN LISTS _Qt_COMPONENTS)
		find_package(Qt5${lib} ${_Qt_FIND_ARGS})
		if(NOT Qt5${lib}_FOUND)
			set(HAVE_QT5 0)
			return()
		endif()
		set(Qt${lib}_LIBRARIES ${Qt5${lib}_LIBRARIES})
		set(Qt${lib}_DEFINITIONS ${Qt5${lib}_DEFINITIONS})
		set(Qt${lib}_INCLUDE_DIRS ${Qt5${lib}_INCLUDE_DIRS})
		set(Qt${lib}_EXECUTABLE_COMPILE_FLAGS ${Qt5${lib}_EXECUTABLE_COMPILE_FLAGS})
	endforeach()
	
	if(HAVE_QT5)
		
		set(QtCore_QTMAIN_LIBRARIES ${Qt5Core_QTMAIN_LIBRARIES})
		
		macro(qt_wrap_ui)
			qt5_wrap_ui(${ARGV})
		endmacro()
		macro(qt_wrap_cpp)
			qt5_wrap_cpp(${ARGV})
		endmacro()
		macro(qt_add_resources)
			qt5_add_resources(${ARGV})
		endmacro()
		
		set(Qt_VERSION ${Qt5Core_VERSION})
		set(HAVE_QT 1)
		
	endif()
	
endif()

function(get_qt4_component VAR QTCOMPONENT)
	if(QTCOMPONENT STREQUAL "Widgets")
		set(${VAR} "Gui" PARENT_SCOPE)
	elseif(QTCOMPONENT STREQUAL "Concurrent")
		set(${VAR} "Core" PARENT_SCOPE)
	else()
		set(${VAR} ${QTCOMPONENT} PARENT_SCOPE)
	endif()
endfunction()

# Otherwise, look for Qt 4
if(NOT HAVE_QT AND (NOT WITH_QT OR WITH_QT EQUAL 4))
	
	set(QT_USE_IMPORTED_TARGETS 1)
	set(_Qt4_COMPONENTS)
	foreach(lib IN LISTS _Qt_COMPONENTS)
		get_qt4_component(_Qt_LIB ${lib})
		list(APPEND _Qt4_COMPONENTS Qt${_Qt_LIB})
	endforeach()
	list(REMOVE_DUPLICATES _Qt4_COMPONENTS)
	find_package(Qt4 COMPONENTS ${_Qt4_COMPONENTS} ${_Qt_FIND_ARGS})
	
	# QT_VERSION_MAJOR check required because of FindQt4.cmake bug
	if(QT4_FOUND AND QT_VERSION_MAJOR EQUAL 4)
		set(HAVE_QT4 1)
		
		foreach(lib IN LISTS _Qt_COMPONENTS)
			get_qt4_component(_Qt_LIB ${lib})
			string(TOUPPER ${_Qt_LIB} _Qt_LIB)
			set(Qt${lib}_LIBRARIES ${QT_QT${_Qt_LIB}_LIBRARY_RELEASE})
			set(Qt${lib}_DEFINITIONS ${QT_DEFINITIONS})
			set(Qt${lib}_INCLUDE_DIRS ${QT_INCLUDE_DIR} ${QT_QT${_Qt_LIB}_INCLUDE_DIR})
			set(Qt${lib}_EXECUTABLE_COMPILE_FLAGS)
		endforeach()
		set(QtCore_QTMAIN_LIBRARIES ${QT_QTMAIN_LIBRARY_RELEASE})
		
		macro(qt_wrap_ui)
			qt4_wrap_ui(${ARGV})
		endmacro()
		macro(qt_wrap_cpp)
			qt4_wrap_cpp(${ARGV})
		endmacro()
		macro(qt_add_resources results)
			set(_Qt_RESOURCES)
			qt4_add_resources(_Qt_RESOURCES ${ARGN})
			set_property(
				SOURCE ${_Qt_RESOURCES}
				APPEND PROPERTY COMPILE_FLAGS " -Wno-missing-declarations"
			)
			list(APPEND ${results} ${_Qt_RESOURCES})
		endmacro()
		
		set(Qt_VERSION "4.${QT_VERSION_MINOR}.${QT_VERSION_PATCH}")
		set(HAVE_QT 1)
		
	endif()
	
endif()

# Always link agains release versions of the Qt libraries
# This is important on windows where we would otherwise end up
# with inconsistencies in the stdlib configuration.
if(HAVE_QT AND MSVC AND NOT DEBUG_EXTRA)
	set(_Qt_LIBRARIES)
	foreach(lib IN LISTS _Qt_COMPONENTS)
		list(APPEND _Qt_LIBRARIES ${Qt${lib}_LIBRARIES})
	endforeach()
	list(APPEND _Qt_LIBRARIES ${Qt${lib}_LIBRARIES})
	foreach(lib IN LISTS arxcrashreporter_qt_LIBRARIES)
		if(TARGET ${lib})
			set_property(TARGET ${lib} PROPERTY MAP_IMPORTED_CONFIG_DEBUG "Release")
		endif()
	endforeach()
endif()

# Get a path to display for the config log
unset(Qt_LIBRARY)
foreach(lib IN LISTS QtCore_LIBRARIES)
	if(TARGET ${lib})
		foreach(var IN ITEMS IMPLIB_RELEASE IMPLIB LOCATION_RELEASE LOCATION)
			get_property(Qt_LIBRARY TARGET ${lib} PROPERTY IMPORTED_${var})
			if(Qt_LIBRARY)
				break()
			endif()
		endforeach()
		if(Qt_LIBRARY)
			break()
		endif()
	endif()
endforeach()
if(NOT Qt_LIBRARY)
	set(Qt_LIBRARY ${QtCore_LIBRARIES})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Qt REQUIRED_VARS Qt_LIBRARY HAVE_QT
                                  VERSION_VAR Qt_VERSION)