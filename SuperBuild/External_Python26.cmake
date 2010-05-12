#-----------------------------------------------------------------------------
set(proj python)

set(python_DEPENDS )

if(Slicer3_USE_PYTHON)
  if(WIN32)
    list(APPEND python_DEPENDS tcl)
  else(WIN32)
    list(APPEND python_DEPENDS tcl tk)
  endif(WIN32)
endif(Slicer3_USE_PYTHON)

  if(WIN32)
  
    set(python_sln ${CMAKE_BINARY_DIR}/${proj}-build/PCbuild/pcbuild.sln)
    string(REPLACE "/" "\\" python_sln ${python_sln})

    # point the tkinter build file to the slicer tcl-build 

    get_filename_component(python_base ${python_sln} PATH)
    get_filename_component(python_home ${python_base} PATH)

    set(python_tkinter ${python_base}/pyproject.vsprops)
    string(REPLACE "/" "\\" python_tkinter ${python_tkinter})

    set(script ${CMAKE_CURRENT_SOURCE_DIR}/../CMake/StringFindReplace.cmake)
    set(out ${python_tkinter})
    set(in ${python_tkinter})

    ExternalProject_Add(${proj}
      DEPENDS ${python_DEPENDS}
      SVN_REPOSITORY "http://svn.python.org/projects/python/branches/release26-maint"
      SOURCE_DIR python-build
      UPDATE_COMMAND ""
      PATCH_COMMAND ${CMAKE_COMMAND} -Din=${in} -Dout=${out} -Dfind=tcltk\" -Dreplace=tcl-build\" -P ${script}
      CONFIGURE_COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /Upgrade
      BUILD_COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project select
      BUILD_IN_SOURCE 1
      INSTALL_COMMAND ""
    )

    # this must match the version of tcl we are building for slicer.
    ExternalProject_Add_Step(${proj} Patch_tcltk_version
      COMMAND ${CMAKE_COMMAND} -Din=${in} -Dout=${out} -Dfind=85 -Dreplace=84 -P ${script}
      DEPENDEES configure
      DEPENDERS build
      )

    ExternalProject_Add_Step(${proj} Build_make_versioninfo
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project make_versioninfo
      DEPENDEES configure
      )
      
    ExternalProject_Add_Step(${proj} Build_make_buildinfo
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project make_buildinfo
      DEPENDEES Build_make_versioninfo
      )
      
    ExternalProject_Add_Step(${proj} Build_kill_python
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project kill_python
      DEPENDEES Build_kill_python
      )
      
    ExternalProject_Add_Step(${proj} Build_w9xpopen
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project w9xpopen
      DEPENDEES Build_kill_python
      )
      
    ExternalProject_Add_Step(${proj} Build_pythoncore
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project pythoncore
      DEPENDEES Build_w9xpopen
      )
      
    ExternalProject_Add_Step(${proj} Build__socket
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _socket
      DEPENDEES Build_pythoncore
      )
      
    ExternalProject_Add_Step(${proj} Build__tkinter
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _tkinter
      DEPENDEES Build__socket
      )
      
    ExternalProject_Add_Step(${proj} Build__testcapi
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _testcapi
      DEPENDEES Build__tkinter
      )
      
    ExternalProject_Add_Step(${proj} Build__msi
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _msi
      DEPENDEES Build__testcapi
      )
      
    ExternalProject_Add_Step(${proj} Build__elementtree
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _elementtree
      DEPENDEES Build__msi
      )
      
    ExternalProject_Add_Step(${proj} Build__ctypes_test
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _ctypes_test
      DEPENDEES Build__elementtree
      )
      
    ExternalProject_Add_Step(${proj} Build__ctypes
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _ctypes
      DEPENDEES python_sln
      )
      
    ExternalProject_Add_Step(${proj} Build_winsound
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project winsound
      DEPENDEES Build__ctypes
      )
      
    ExternalProject_Add_Step(${proj} Build_pyexpat
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project pyexpat
      DEPENDEES Build_winsound
      )
      
    ExternalProject_Add_Step(${proj} Build_pythonw
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project pythonw
      DEPENDEES Build_pyexpat
      )
      
    ExternalProject_Add_Step(${proj} Build__multiprocessing
      COMMAND ${CMAKE_BUILD_TOOL} ${python_sln} /build Release /project _multiprocessing
      DEPENDEES Build_pythonw
      )

    ExternalProject_Add_Step(${proj} CopyPythonLib
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/python-build/PCbuild/python26.lib ${CMAKE_BINARY_DIR}/python-build/Lib/python26.lib 
      DEPENDEES install
      )
    ExternalProject_Add_Step(${proj} Copy_socketPyd
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/python-build/PCbuild/_socket.pyd ${CMAKE_BINARY_DIR}/python-build/Lib/_socket.pyd 
      DEPENDEES install
      )
    ExternalProject_Add_Step(${proj} Copy_ctypesPyd
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/python-build/PCbuild/_ctypes.pyd ${CMAKE_BINARY_DIR}/python-build/Lib/_ctypes.pyd
      DEPENDEES install
      )
      
    ExternalProject_Add_Step(${proj} CopyPythonDll
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/python-build/PCbuild/python26.dll ${CMAKE_BINARY_DIR}/Slicer3-build/bin/${CMAKE_BUILD_TYPE}/python26.dll
      DEPENDEES install
      )
  elseif(APPLE)
    set(python_SVN "http://svn.python.org/projects/python/branches/release26-maint")
    set(python_BUILD_IN_SOURCE 1)
    set(python_CONFIGURE sh configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/python-build --with-tcl=${tcl_build} --enable-shared)
    set(python_BUILD make)
    set(python_INSTALL make install)

    ExternalProject_Add(${proj}
      DEPENDS ${python_DEPENDS}
      SVN_REPOSITORY ${python_SVN}
      SOURCE_DIR python
      BUILD_IN_SOURCE ${python_BUILD_IN_SOURCE}
      CONFIGURE_COMMAND ${python_CONFIGURE}
      BUILD_COMMAND ${python_BUILD}
      INSTALL_COMMAND ${python_INSTALL}
      )
#  if { $isDarwin } {
#            # Special Slicer hack to build and install the .dylib
#            file mkdir $::Slicer3_LIB/python-build/lib/
#            file delete -force $::Slicer3_LIB/python-build/lib/libpython2.6.dylib
#            set fid [open environhack.c w]
#            puts $fid "char **environ=0;"
#            close $fid
#            runcmd gcc -c -o environhack.o environhack.c
#            runcmd libtool -o $::Slicer3_LIB/python-build/lib/libpython2.6.dylib -dynamic  \
#                -all_load libpython2.6.a environhack.o -single_module \
#                -install_name $::Slicer3_LIB/python-build/lib/libpython2.6.dylib \
#                -compatibility_version 2.6 \
#                -current_version 2.6 -lSystem -lSystemStubs
#
# 
  else()
    set(python_SVN "http://svn.python.org/projects/python/branches/release26-maint")
    set(python_BUILD_IN_SOURCE 1)
    set(python_CONFIGURE sh configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/python-build --with-tcl=${tcl_build} --enable-shared)
    set(python_BUILD make)
    set(python_INSTALL make install)

    ExternalProject_Add(${proj}
      DEPENDS ${python_DEPENDS}
      SVN_REPOSITORY ${python_SVN}
      SOURCE_DIR python
      BUILD_IN_SOURCE ${python_BUILD_IN_SOURCE}
      CONFIGURE_COMMAND ${python_CONFIGURE}
      BUILD_COMMAND ${python_BUILD}
      INSTALL_COMMAND ${python_INSTALL}
      )
  endif()


#-----------------------------------------------------------------------------
# Set vtk_PYTHON_ARGS, slicer_PYTHON_INCLUDE and slicer_PYTHON_LIBRARY variables
#

set(vtk_PYTHON_ARGS)
set(slicer_PYTHON_INCLUDE)
set(slicer_PYTHON_LIBRARY)
set(slicer_PYTHON_EXECUTABLE)

if(WIN32)
  set(slicer_PYTHON_INCLUDE ${CMAKE_BINARY_DIR}/Python-build/Include)
  set(slicer_PYTHON_LIBRARY ${CMAKE_BINARY_DIR}/Python-build/PCbuild/python26.lib)
  set(slicer_PYTHON_EXECUTABLE ${CMAKE_BINARY_DIR}/Python-build/PCbuild/python.exe)
elseif(APPLE)
  set(slicer_PYTHON_INCLUDE ${CMAKE_BINARY_DIR}/python-build/include/python2.6)
  set(slicer_PYTHON_LIBRARY ${CMAKE_BINARY_DIR}/python-build/lib/libpython2.6.dylib)
  set(slicer_PYTHON_EXECUTABLE ${CMAKE_BINARY_DIR}/python-build/bin/python)
else()
  set(slicer_PYTHON_INCLUDE ${CMAKE_BINARY_DIR}/python-build/include/python2.6)
  set(slicer_PYTHON_LIBRARY ${CMAKE_BINARY_DIR}/python-build/lib/libpython2.6.so)
  set(slicer_PYTHON_EXECUTABLE ${CMAKE_BINARY_DIR}/python-build/bin/python)
endif()

if(Slicer3_USE_PYTHON)
  set(vtk_PYTHON_ARGS
    -DPYTHON_INCLUDE_PATH:PATH=${slicer_PYTHON_INCLUDE}
    -DPYTHON_LIBRARY:FILEPATH=${slicer_PYTHON_LIBRARY}
    )
endif(Slicer3_USE_PYTHON)
