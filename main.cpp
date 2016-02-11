#include <iostream>
#include <boost/locale.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/filesystem/fstream.hpp>


int main() {
	std::cout << "Create and install global locale..." << std::endl;

	std::locale::global(boost::locale::generator().generate(""));
	std::cout << "Make boost FS use it..." << std::endl;
	boost::filesystem::path::imbue(std::locale());

    boost::filesystem::ofstream hello("пример.txt");
    hello << "привет! שלום";
	std::cout << "Text file created" << std::endl;
    return 0;
}