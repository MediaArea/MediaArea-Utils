<?php

/*
Check links for MediaInfo and MediaConch download pages

Usage :
php checkMediaAreaLinks.php --project=mi --directory=MediaArea-Website
php checkMediaAreaLinks.php --project=mc --directory=MediaConch-Website

Copyright (c) MediaArea.net SARL. All Rights Reserved.
Use of this source code is governed by a BSD-style license that
can be found in the License.txt file in the root of the source
tree.
*/

require(__DIR__ . '/checkLinks.class.php');

$options = getopt('', array('project:', 'directory::'));
if (isset($options['project']) && in_array($options['project'], array('mi', 'mc'))) {
    switch ($options['project']) {
        case 'mi':
            $directory = 'www/www_data/en/MediaInfo/Download/';
            break;
        case 'mc':
            $directory = 'downloads/';
            break;
    }
}
else {
    exit('You should specify a project to check (--project=)' . "\n" . 'Currently only MediaInfo (mi) and MediaConch (mc) are supported' . "\n");
}

if (isset($options['directory']) && '' != $options['directory']) {
    if ('/' != substr($options['directory'], -1)) {
        $directory = '/' . $directory;
    }
    $directory = $options['directory'] . $directory;
}

$checkLinks = new checkLinks();
$checkLinks->setDirectory($directory);
$checkLinks->setPattern('|http[s]?://mediaarea.net/download/[a-zA-Z0-9\.\/_+\-]+|');
$checkLinks->checkLinks();
