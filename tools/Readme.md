## File to binary representation in header structure

### Compilation

On Linux and Mac: use g++ file\_to\_bin.cpp -o file\_to\_bin

On Windows: :)

### Params

* **-i**: input file to transform
* **-o**: output file where the structure header will be transformed
* **-s**: name of the structure


### MediaConch Usage

#### Requirement

* $Mediaconch referes to https://github.com/MediaArea/MediaConch repository.
* $MC_SC referes to https://github.com/MediaArea/MediaConch\_SourceCode repository.

If you modify a copy of an original file, remmeber to change the original too.

#### Implementation/policy checker

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/ImplementationReportXsl.h -s implementation_report_xsl
```

Original FILE\_XSL can be found in $Mediaconch/MetadataDevelopment/ImplementationChecks/implementationCheckEBML.xsl


#### Implementation/policy display text

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/ImplementationReportDisplayTextXsl.h -s implementation_report_display_text_xsl
```

Original FILE\_XSL can be found in $MC\_SC/Source/Resource/displays/MediaConchText.xsl


#### Implementation/policy display text unicode

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/ImplementationReportDisplayTextUnicodeXsl.h -s implementation_report_display_text_unicode_xsl
```

Original FILE\_XSL can be found in $MC\_SC/Source/Resource/displays/MediaConchTextUnicode.xsl


#### Implementation/policy display html

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/ImplementationReportDisplayHtmlXsl.h -s implementation_report_display_html_xsl
```

Original FILE\_XSL can be found in $MC\_SC/Source/Resource/displays/MediaConchHtml.xsl


#### Implementation/policy display XML

Can be found $MC\_SC/Source/Resource/displays/MediaConchXml.xsl, should be an empty file (used by the GUI).


#### Implementation Matroska Schema

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/ImplementationReportMatroskaSchema.h -s xsl_schema_matroska_schema
```

Original FILE\_XSL can be found in $Mediaconch/MetadataDevelopment/ImplementationChecks/MatroskaSchema.xml


#### Media Trace display Html

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/MediaTraceDisplayHtmlXsl.h -s media_trace_display_html_xsl
```

Original FILE\_XSL can be found in $Mediaconch/MetadataDevelopment/Displays/HTMLOutput/MediaTrace.xsl


#### Media Trace display Text

``` C
./file\_to\_bin -i FILE_XSL -o $MC_SC/Source/Common/MediaTraceDisplayTextXsl.h -s media_trace_display_text_xsl
```

Original FILE\_XSL can be found in $Mediaconch/MetadataDevelopment/Displays/TextOutput/MediaTraceText.xsl
