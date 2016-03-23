/*  Copyright (c) MediaArea.net SARL. All Rights Reserved.
 *
 *  Use of this source code is governed by a GPLv3+/MPLv2+ license that can
 *  be found in the License.html file in the root of the source tree.
 */

#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <algorithm>
#include <getopt.h>

static int usage(void)
{
    std::cerr << "tool -i XSL_FILE -o NAME -s STRUCT" << std::endl;
    std::cerr << "Copy the XSL_FILE into a data structure named STRUCT in C++ in file NAME" << std::endl;
    return 1;
}

static int append_licence(std::ofstream& out)
{
    out << "/*  Copyright (c) MediaArea.net SARL. All Rights Reserved." << std::endl;
    out << " *" << std::endl;
    out << " *  Use of this source code is governed by a GPLv3+/MPLv2+ license that can" << std::endl;
    out << " *  be found in the License.html file in the root of the source tree." << std::endl;
    out << " */" << std::endl;
    out << std::endl << std::endl;
    return 0;
}

static int append_header(const std::string& title, const std::string& structure, std::ofstream& out)
{
    std::string def(title);
    std::transform(def.begin(), def.end(), def.begin(), ::toupper);
    std::replace(def.begin(), def.end(), ' ', '_');
    std::replace(def.begin(), def.end(), '.', '_');
    out << "#ifndef " << def << std::endl;
    out << "#define " << def <<std::endl;

    out << std::endl << std::endl;
    out << "const char " << structure << "[] = {" << std::endl;
    return 0;
}

static int append_footer(std::ofstream& out)
{
    out << ", '\\0'";
    out << "};";
    out << std::endl << std::endl << std::endl;
    out << "#endif";
    out << std::endl;
    return 0;
}

static int append_body(std::ifstream& in, std::ofstream& out)
{
    char c;

    in.seekg (0, in.end);
    int length = in.tellg();
    in.seekg (0, in.beg);
    char *buffer = new char[length];

    in.read (buffer, length);
    for (int first = 0; first < length; ++first)
    {
        if (first)
            out << ",";
        char b[16] = {0};
        int len = snprintf(b, 15, "'\\x%.02x'", buffer[first]&0xFF);
        if (len < 0)
            continue;
        b[len] = '\0';
        out << b;
        if (buffer[first] == '\n' || buffer[first] == '\r')
            out << std::endl;
    }
    delete buffer;
    return 0;
}

static int do_one_file(const std::string& in, const std::string& out, const std::string& structure)
{
    std::ifstream fs(in.c_str(), std::ifstream::binary);
    if (!fs)
    {
        std::cerr << "cannot open file: " << in << std::endl;
        return 1;
    }

    std::cout << "writting " << in << " to: " << out << " with structure name" << structure << std::endl;
    std::ofstream out_stream(out.c_str(), std::ofstream::out | std::ofstream::trunc);
    if (!out_stream.is_open())
        return 1;

    if (append_licence(out_stream))
        return 1;

    if (append_header(out, structure, out_stream))
        return 1;

    if (append_body(fs, out_stream))
        return 1;

    if (append_footer(out_stream))
        return 1;

    out_stream.close();
    return 0;
}

int main(int argc, char *argv[])
{
    std::string in, out, structure;

    while (1)
    {
        int this_option_optind = optind ? optind : 1;
        int option_index = 0;
        static struct option long_options[] =
            {
                {"in",        required_argument, 0,  'i' },
                {"out",       required_argument, 0,  'o' },
                {"structure", required_argument, 0,  's' },
                {0          , 0                , 0,  0 }
            };

        int c = getopt_long(argc, argv, "i:o:s:",
                            long_options, &option_index);
        if (c == -1)
            break;

        switch (c)
        {
            case 'i':
                in = std::string(optarg);
                break;

            case 'o':
                out = std::string(optarg);
                break;

            case 's':
                structure = std::string(optarg);
                break;

            default:
                return usage();
        }
    }

    if (optind != argc)
        return usage();

    if (!in.length() || !out.length() || !structure.length())
        return usage();

    return do_one_file(in, out, structure);
}
