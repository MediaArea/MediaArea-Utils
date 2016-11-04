----------
MediaConch
----------

Website: https://mediaarea.net/MediaConch

---------
Licensing
---------

All open source digital assets for the software developed by MediaArea during the PREFORMA project will be made available under the open access license: Creative Commons license attribution – Sharealike 4.0 International (CC BY-SA v4.0). All assets will exist in open file formats within an open platform (an open standard as defined in the European Interoperability Framework for Pan-European eGovernment Service (version 1.0 2004)).

-----------------------
How to build MediaConch
-----------------------
Download and unzip the src05*.zip. Enter the new directory created.
Download and unzip the buildenv05*.zip.

Move the content of the buildenv to the build directory by typing:
mv buildenv05/* .

To build the CLI, type:
./CLI_compile.sh

To build the server, type:
./Server_compile.sh

To build the GUI, type:
export PATH="$PWD/Qt/5.3/clang_64/bin:$PATH"
./GUI_compile.sh
macdeployqt MediaConch/Project/Qt/MediaConch.app
