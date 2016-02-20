#include <iostream>
#include <fstream>
#include <locale>

#if _MSC_VER == 1900
#include <windows.h>
#include <locale.h>
#include <filesystem>
#else
#include <boost/locale.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/filesystem/fstream.hpp>
#include <boost/container/string.hpp>
#endif


int main() {
	std::ios_base::sync_with_stdio(false);
	std::cout << "Create and install global locale..." << std::endl;
	std::wstring name(L"empty");

#if _MSC_VER == 1900
	auto p(std::experimental::filesystem::u8path(u8"\u043f\u0440\u0438\u0432\u0435\u0442.txt")); 
	std::ofstream hello(p);
	hello.imbue(std::locale());
#else
	std::locale::global(boost::locale::generator().generate(""));
	std::cout << "Make boost FS use it..." << std::endl;
	boost::filesystem::path::imbue(std::locale());
	boost::filesystem::path p("пример.txt"); 
    name = p.wstring();
	std::wstring  tmp(L"\u0442\u0435\u0441\u0442");
	boost::filesystem::ofstream hello(p); // can be use by pass "пример.txt" (implicity ctor boost::path)
	hello.imbue(std::locale());
	hello << name;
	hello << tmp;
	name = L"\n \u0441\u0442\u0440\u043e\u043a\u0430 ";
	hello << name;
#endif
    hello << std::endl << "привет! שלום " << std::endl; // привет! שלום 
	std::cout << "Text file created" << std::endl << "привет! שלום ";
    return 0;
}