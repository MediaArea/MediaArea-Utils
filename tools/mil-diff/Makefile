CREATE_XML_MASTER=create_xml_master
CREATE_XML_NEW=create_xml_new

ifdef PKG_CONFIG_PATH_MASTER
	ifneq ("$(wildcard ${PKG_CONFIG_PATH_MASTER}/libmediainfo-config)", "")
		MEDIAINFOLIB_MASTER+=`"${PKG_CONFIG_PATH_MASTER}/libmediainfo-config" LIBS_Static`
		MEDIAINFOLIB_MASTER+=-I"${PKG_CONFIG_PATH_MASTER}/../../../Source/"
	else
		MEDIAINFOLIB_MASTER+=`pkg-config --cflags --libs libmediainfo`
	endif
else
	MEDIAINFOLIB_MASTER+=`pkg-config --cflags --libs libmediainfo`
endif

ifdef PKG_CONFIG_PATH_NEW
	ifneq ("$(wildcard ${PKG_CONFIG_PATH_NEW}/libmediainfo-config)", "")
		MEDIAINFOLIB_NEW+=`"${PKG_CONFIG_PATH_NEW}/libmediainfo-config" LIBS_Static`
		MEDIAINFOLIB_NEW+=-I"${PKG_CONFIG_PATH_NEW}/../../../Source/"
	else
		MEDIAINFOLIB_NEW+=`pkg-config --cflags --libs libmediainfo`
	endif
else
	MEDIAINFOLIB_NEW+=`pkg-config --cflags --libs libmediainfo`
endif

ZENLIB=`pkg-config --libs libzen`

all:	$(CREATE_XML_MASTER) \
	$(CREATE_XML_NEW)

$(CREATE_XML_MASTER): Source/create_xml.cpp
	g++ Source/create_xml.cpp $(MEDIAINFOLIB_MASTER) $(ZENLIB) -DUNICODE -o $(CREATE_XML_MASTER)

$(CREATE_XML_NEW): Source/create_xml.cpp
	g++ Source/create_xml.cpp $(MEDIAINFOLIB_NEW) $(ZENLIB) -DUNICODE -o $(CREATE_XML_NEW)
