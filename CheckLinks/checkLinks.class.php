<?php

/*
Check links extracted from files in a directory

Copyright (c) MediaArea.net SARL. All Rights Reserved.
Use of this source code is governed by a BSD-style license that
can be found in the License.txt file in the root of the source
tree.
*/

class checkLinks
{
    protected $pattern;
    protected $directory;
    protected $files = array();
    protected $links = array();
    protected $infos = array();

    public function __construct()
    {
        $this->infos = array('links' => 0, 'ok' => 0, 'nok' => 0);
    }

    public function setDirectory($directory)
    {
        $this->directory = $directory;
    }

    public function setPattern($pattern)
    {
        $this->pattern = $pattern;
    }

    public function checkLinks()
    {
        $this->findFiles();

        if (count($this->files) > 0) {
            foreach ($this->files as $file) {
                $file = $this->directory . $file;
                echo 'Checking links for file ' . $file . "\n";
                $this->findLinks($file);

                if (count($this->links) > 0) {
                    foreach ($this->links as $link) {
                        $this->infos['links']++;
                        $status = $this->checkLink($link);
                        if ($status) {
                            $this->infos['ok']++;
                        }
                        else {
                            $this->infos['nok']++;
                            echo $link . ' => NOK' . "\n";
                        }
                    }
                }
            }
        }

        echo "\n" .
            'Total links : ' . $this->infos['links'] . "\n" .
            'Links OK : ' . $this->infos['ok'] . "\n" .
            'Links NOK : ' . $this->infos['nok'] . "\n";
    }

    protected function findFiles()
    {
        $list = scandir($this->directory);
        foreach ($list as $key => $entry) {
            if (!is_file($this->directory . $entry)) {
                unset($list[$key]);
            }
        }

        $this->files = $list;
    }

    protected function findLinks($file)
    {
        $content = file_get_contents($file);
        preg_match_all($this->pattern, $content, $links);
        if (isset($links[0]) && count($links[0]) > 0) {
            $this->links = $links[0];
        }
        else {
            $this->links = array();
        }
    }

    protected function checkLink($link)
    {
        // handle links without http/https prefix
        if ('//' == substr($link, 0, 2)) {
            $link = 'https:' . $link;
        }

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $link);
        curl_setopt($curl, CURLOPT_HEADER, true);
        curl_setopt($curl, CURLOPT_FOLLOWLOCATION, false);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_NOBODY, true);
        $response = curl_exec($curl);
        $headers = curl_getinfo($curl);
        curl_close($curl);

        if (isset($headers['http_code']) && $headers['http_code'] == 200) {
            return true;
        }
        else {
            return false;
        }
    }
}
