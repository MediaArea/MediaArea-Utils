#!/usr/bin/python

import os.path
import urllib2
import sys
import os

import xml.etree.ElementTree as ElementTree

def download_file(url, path):
    destination = os.path.join(path, url.split('/')[-1])

    if not os.path.exists(path):
        os.makedirs(path)

    if os.path.isfile(destination):
        print("INFO: already downloaded: " + destination)
        return
    else:
        print("download file: " + url)
        try:
            input_file = urllib2.urlopen(url)
        except urllib2.HTTPError as e:
            print('ERROR: unable to download file %s, server error: %i %s' % (url, e.code, e.reason))
            return
        except urllib2.URLError as e:
            print('ERROR: unable to download file %s, reason: %s' % (url, e.reason))
            return

        try:
            output_file = open(destination, 'wb')
            while True:
                data = input_file.read(4096)
                if data:
                    output_file.write(data)
                else:
                    break
        except IOError as e:
            print('ERROR: unable to write file %s to disk, reason: %s' % (destination, e.strerror))
            output_file.close()
            os.remove(destination)
            return

        input_file.close()
        output_file.close()

def parse_xml(url, path):
    global recurse

    try:
        main_xml = urllib2.urlopen(url).read()
    except urllib2.HTTPError as e:
        print('ERROR: unable to fetch xml %s, server error: %i %s' % (url, e.code, e.reason))
    except urllib2.URLError as e:
        print('ERROR: unable to fetch xml %s, reason: %s' % (url, e.reason))


    root = ElementTree.fromstring(main_xml)

    for element in root:
        if element.tag == 'item':
            title = ''
            link = ''
            type = ''
            for children in element:
                if children.tag == 'title' and element.attrib.get('type', '') == 'folder':
                    title = children.text
                if children.tag == 'link':
                    link = children.text
                    type = children.attrib.get('type', '')

            if link:
                if type == 'application/xml':
                    if recurse <= limit:
                        recurse += 1
                        parse_xml(link, os.path.join(path, title))
                        recurse -= 1
                    else:
                        print("ERROR: too many recursion levels")
                        return
                else:
                    download_file(link, os.path.join(path, title))

recurse = 0
limit = 15

if len(sys.argv) < 2:
    print('usage: %s destination <url>' % sys.argv[0])
    exit(1)
elif len(sys.argv) > 2:
    url = sys.argv[2]
else:
    url = 'http://akamai-progressive.irt.de/info.xml'

dst = sys.argv[1]

parse_xml(url, dst)
