----------
MediaConch
----------

Website: https://mediaarea.net/MediaConch

---------
Licensing
---------

All open source digital assets for the software developed by MediaArea during the PREFORMA project will be made available under the open access license: Creative Commons license attribution – Sharealike 4.0 International (CC BY-SA v4.0). All assets will exist in open file formats within an open platform (an open standard as defined in the European Interoperability Framework for Pan-European eGovernment Service (version 1.0 2004)).

--------------------------------------
How to install the build environnement
--------------------------------------

Download and unzip the buildenv09*.zip. Enter the directory
corresponding to your version and your architecture, and type :

```sh
dpkg -i *
```

-----------------------
How to build MediaConch
-----------------------

Download and unzip the src09*.zip. Enter the new directory created.

To build the CLI, type:

```sh
./CLI_compile.sh
```

To build the server, type:
```sh
./Server_compile.sh
```

To build the GUI, type:
```sh
./GUI_compile.sh
```
