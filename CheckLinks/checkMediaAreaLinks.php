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

require __DIR__.'/checkLinks.class.php';

$projects = array('mi', 'mc', 'qc', 'am', 'bm', 'dv', 'dr', 'mm', 'rc');
$options = getopt('', array('project:', 'directory::'));
if (isset($options['project']) && in_array($options['project'], $projects)) {
    switch ($options['project']) {
        case 'mi':
            $directory = 'src/MediaInfoBundle/Resources/views/Download/';
            break;
        case 'mc':
            $directory = 'src/MediaConchBundle/Resources/views/Download/';
            break;
        case 'qc':
            $directory = 'src/QCToolsBundle/Resources/views/Download/';
            break;
        case 'am':
            $directory = 'src/AVIMetaEditBundle/Resources/views/Download/';
            break;
        case 'bm':
            $directory = 'src/BWFMetaEditBundle/Resources/views/Download/';
            break;
        case 'dv':
            $directory = 'src/DVAnalyzerBundle/Resources/views/Download/';
            break;
        case 'dr':
            $directory = 'src/DVRescueBundle/Resources/views/Download/';
            break;
        case 'mm':
            $directory = 'src/MOVMetaEditBundle/Resources/views/Download/';
            break;
        case 'rc':
            $directory = 'src/RAWcookedBundle/Resources/views/Download/';
            break;
    }
} else {
    exit('You should specify a project to check (--project=)'."\n".'Supported: '.implode(',', $projects)."\n");
}

if (isset($options['directory']) && '' != $options['directory']) {
    if ('/' != substr($options['directory'], -1)) {
        $directory = '/'.$directory;
    }
    $directory = $options['directory'].$directory;
}

$checkLinks = new checkLinks();
$checkLinks->setDirectory($directory);
$checkLinks->setPattern('|(http[s]?:)?//mediaarea.net/download/[a-zA-Z0-9\.\/_+\-]+|');
$checkLinks->checkLinks();
