#include <iostream>
#include <fstream>
#include <boost/locale.hpp>
#include <boost/system/error_code.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/filesystem/fstream.hpp>


int main() {
	std::cout << "Create and install global locale..." << std::endl;
	boost::system::error_code e;

	//std::locale l;
	std::locale::global(boost::locale::generator().generate(""));
	std::cout << "Make boost FS use it..." << std::endl;
	boost::filesystem::path::imbue(std::locale());

	//std::ofstream hello("пример.txt");
	//hello.imbue(std::locale());
    boost::filesystem::ofstream hello("пример.txt");
    hello << "привет! שלום";
	std::cout << "Text file created" << std::endl;
    return 0;
}