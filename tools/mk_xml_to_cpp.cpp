/*  Copyright (c) MediaArea.net SARL. All Rights Reserved.
 *
 *  Use of this source code is governed by a GPLv3+/MPLv2+ license that can
 *  be found in the License.html file in the root of the source tree.
 *
 * dependencies: tinyxml2 re2
 * compile: g++ -std=c++11 `pkg-config --libs --cflags tinyxml2 re2` mk_xml_to_cpp.cpp
*/

#include <map>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <getopt.h>
#include <re2/re2.h>
#include <tinyxml2.h>

struct Element {
    std::string id;
    std::string name;
    std::string path;
    std::string type;
    std::string comment;
    bool recursive;
    bool has_body;
    bool has_child;
};

static bool child_of(const std::string& parent, const std::string& element) {
    return element.find(parent + '_') == 0 ? true : false;
}

static bool has_body(const std::string& name, const std::string& cpp) {
    return RE2::PartialMatch(cpp, "(?m)^void File_Mk::" + name + "\\(\\)");
}

static void update_header(std::stringstream& out, const std::vector<Element>& el) {
    std::map<std::string, std::string> types = {
        { "binary", "Skip_XX(Element_Size, \"Data\");" },
        { "uinteger", "UInteger_Info();" },
        { "integer", "UInteger_Info();" },
        { "float", "Float_Info();" },
        { "string", "String_Info();" },
        { "utf-8", "UTF8_Info();" }
    };

    for(const Element& e : el) {
        std::string t = types.find(e.type) != types.end() ? types.at(e.type) : "";

        if(e.has_body) {
            out << "    void " << e.path << "();" << std::endl;
        }
        else {
            out << "    void " << e.path << "(){" << t << "};" << std::endl;
        }
    }
}

static void update_namespace(std::stringstream& out, const std::vector<Element>& el) {
    for(const Element& e : el) {
        out << "    const int64u " << e.path << "=" << e.id << ";" << e.comment << std::endl;
    }
}

static size_t update_data_blk(std::stringstream& out, const std::vector<Element>& el,
                              size_t index = 0, const std::string& parent = "",
                              const std::string& prefix = "", bool recurse = true) {
    size_t i = index;

    for(; i < el.size(); ++i) {

        // skip Segment_Attachments_AttachedFile_FileData content
        if (el.at(i).path == "Segment_Attachments_AttachedFile_FileData") {
            out << prefix << "LIST_SKIP(" << el.at(i).path << ") "
                << "//This is ATOM, but some ATOMs are too big" << std::endl;
            continue;
        }

        // write Segment_Cluster_BlockGroup_Block body inside Segment_Cluster_SimpleBlock block
        if (el.at(i).path == "Segment_Cluster_SimpleBlock") {
            out << prefix << "LIS2(Segment_Cluster_SimpleBlock, \"SimpleBlock\")" << std::endl
                << prefix << "    ATOM_BEGIN" << std::endl;

            update_data_blk(out,
                            el,
                            std::find_if(el.begin(), el.end(),
                            [&](Element e, std::string name ="") {
                                return e.path == "Segment_Cluster_BlockGroup_Block";
                             } ) - el.begin() + 1,
                             "Segment_Cluster_BlockGroup_Block",
                             prefix + "    ",
                             true);

            out << prefix << "    ATOM_END_MK" << std::endl;
            continue;
        }

        if(parent == "" || child_of(parent, el.at(i).path) ) {
            if(el.at(i).has_child) {
                out << prefix << "LIS2(" << el.at(i).path << ", \""
                    << el.at(i).name << "\")" << std::endl
                    << prefix << "    ATOM_BEGIN" << std::endl;

                if(el.at(i).recursive && recurse) {
                    update_data_blk(out, el, i , parent, prefix + "        ", false);
                }

                    i = update_data_blk(out, el, i + 1, el.at(i).path, prefix + "    ", true);

                out << prefix << "    ATOM_END_MK" << std::endl;
            }
            else {
                out << prefix << "ATO2(" << el.at(i).path << ", \""
                    << el.at(i).name << "\")" << std::endl;
            }
        }
        else {
           break;
       }
    }

    // remove trailing endl
    if(parent == "") {
        std::string temp = out.str();
        temp.pop_back();
        out.str(temp);
    }

    return i - 1;
}

static int file_read(const std::string& path, std::string& output) {
    std::ifstream input(path);
    std::stringstream buffer;

    if(input.bad()) {
        return 1;
    }

    buffer << input.rdbuf();
    output = buffer.str();

    return 0;
}

static int file_write(const std::string& path, const std::string& data) {
    std::ofstream output(path);

    if(output.bad()) {
        return 1;
    }

    output << data;

    return 0;
}

static std::string path_to_cpp(const std::string& path) {
    std::string temp = "";

    for(size_t start = path.find_first_of('\\');
               start != std::string::npos;
               start = path.find_first_of('\\', start + 1)) {
        size_t stop = std::min({
            path.find_first_of('(', start + 1),
            path.find_first_of(')', start + 1),
            path.find_first_of('\\', start + 1)
        });

        if(path.find_first_of('\\') != start) {
            temp += '_';
        }

        temp += path.substr(start + 1, stop - (start + 1));
    }

    return temp;
}

static std::string id_to_string(const std::string& id) {
    unsigned long temp = std::stoul(id, nullptr, 16);
    unsigned long mask = temp;

    std::stringstream sstream;

    mask |= mask >> 1;
    mask |= mask >> 2;
    mask |= mask >> 4;
    mask |= mask >> 8;
    mask |= mask >> 16;
    mask |= mask >> 32;
    mask = mask >> 1;

    temp = temp & mask;

    sstream << "0x" << std::hex << std::uppercase << temp;

    return sstream.str();
}

static int process(const std::string& xml, const std::string& cpp, const std::string header) {
    tinyxml2::XMLDocument xml_data;
    std::string cpp_data;
    std::string header_data;

    if(xml_data.LoadFile(xml.c_str()) != 0) {
        std::cerr << "ERROR: unable to parse xml file" << std::endl;
        return 1;
    }

    const tinyxml2::XMLElement* root = xml_data.FirstChildElement("EBMLSchema");

    if(root == nullptr) {
        std::cerr << "ERROR: EBMLSchema root not found" << std::endl;
        return 1;
    }

    if(file_read(cpp, cpp_data) != 0) {
        std::cerr << "ERROR: unable to read cpp file" << std::endl;
        return 1;
    }

    if(file_read(header, header_data) != 0) {
        std::cerr << "ERROR: unable to read header file" << std::endl;
        return 1;
    }

    std::vector<Element> el;

    for(const tinyxml2::XMLElement* e = root->FirstChildElement();
                                    e != 0;
                                    e = e->NextSiblingElement()) {

        std::string id = e->Attribute("id") ? id_to_string(e->Attribute("id")) : "";
        std::string name = e->Attribute("name") ? e->Attribute("name") : "";
        std::string path = e->Attribute("path") ? path_to_cpp(e->Attribute("path")) : "";
        std::string type = e->Attribute("type") ? e->Attribute("type") : "";

        if(type == "binary" && RE2::PartialMatch(name, "UID$") && e->IntAttribute("size") == 16) {
            type = "uinteger";
        }

        el.push_back(Element { id,
                               name,
                               path,
                               type,
                               "",
                               e->BoolAttribute("recursive"),
                               has_body(path, cpp_data),
                               false } );

        if(el.size() > 1 && child_of(el.at(el.size() - 2).path, path)) {
            el.at(el.size() - 2).has_child = true;
        }

        // add Segment_Cluster_BlockGroup_Block_Lace element
        if(path == "Segment_Cluster_BlockGroup_Block") {
            el.push_back(Element { "0xFFFFFFFFFFFFFFFELL",
                                   "Lace",
                                   "Segment_Cluster_BlockGroup_Block_Lace",
                                   "master",
                                   " //Fake one",
                                   false,
                                   has_body("Segment_Cluster_BlockGroup_Block_Lace", cpp_data),
                                   false
            } );

            el.at(el.size() - 2).has_child = true;
        }
    }

    std::stringstream output;

    update_header(output, el);

    const char* expr1 = R"%((?m)(^\s*void Segment(.*\n))+)%";
    if(!RE2::Replace(&header_data, expr1, output.str())) {
        std::cerr << "ERROR: update of header failed" << std::endl;
        return 1;
    }

    output.str("");
    output.clear();

    update_namespace(output, el);

    const char* expr2 = R"%((?ms)^\s*const int64u Segment=\S[^}]+)%";
    if(!RE2::Replace(&cpp_data, expr2, output.str())) {
        std::cerr << "ERROR: update of namespace block failed" << std::endl;
        return 1;
    }

    output.str("");
    output.clear();

    update_data_blk(output, el, 0, "", "    ", true);

    const char* expr3 = R"%((?ms)^\s*LIS[T2]\(Segment(, "Segment")?\).*^\s*ATOM_END_MK)%";
    if(!RE2::Replace(&cpp_data, expr3, output.str())) {
        std::cerr << "ERROR: update of parsing block failed" << std::endl;
        return 1;
    }

    if(file_write(cpp, cpp_data) != 0) {
        std::cerr << "ERROR: unable to write cpp file" << std::endl;
        return 1;
    }

    if(file_write(header, header_data) != 0) {
        std::cerr << "ERROR: unable to write header file" << std::endl;
        return 1;
    }

    return 0;
}

static int usage(const char* name) {
    std::cerr << name << " -i XML_FILE -o CPP_FILE -h HEADER_FILE" << std::endl
              << "Update matroska segments definitions from eblm matroska xml" << std::endl;

    return 1;
}

int main(int argc, char** argv) {
    std::string xml = "";
    std::string cpp = "";
    std::string header = "";

    for(int c = getopt(argc, argv, "i:o:h:"); c != -1; c = getopt(argc, argv, "i:o:h:")) {
        switch (c) {
            case 'i':
                xml = std::string(optarg);
                break;
            case 'o':
                cpp = std::string(optarg);
                break;
            case 'h':
                header = std::string(optarg);
                break;
            default:
                return usage(argv[0]);
        }
    }

    if(xml == "" || cpp == "" || header == "") {
        return usage(argv[0]);
    }

    return process(xml, cpp, header);
}
