#include "gateway_mac_finder.h"

#include <winsock2.h>
#include <iphlpapi.h>
#include <windows.h>
#include <WS2tcpip.h>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>

#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "Ws2_32.lib")

std::string getGatewayMACAddress(const std::string &gatewayAddress)
{
    ULONG bufferSize = 0;
    GetIpNetTable(nullptr, &bufferSize, FALSE);

    std::vector<unsigned char> buffer(bufferSize);

    if (GetIpNetTable(reinterpret_cast<PMIB_IPNETTABLE>(buffer.data()), &bufferSize, FALSE) ==
        NO_ERROR)
    {
        auto arpTable = reinterpret_cast<PMIB_IPNETTABLE>(buffer.data());

        for (int i = 0; i < static_cast<int>(arpTable->dwNumEntries); ++i)
        {
            auto &row = arpTable->table[i];
            in_addr addr;
            inet_pton(AF_INET, gatewayAddress.c_str(), &addr);
            if (row.dwAddr == addr.S_un.S_addr)
            {

                std::stringstream macStream;
                macStream << std::hex << std::uppercase
                          << static_cast<int>(row.bPhysAddr[0]) << ":"
                          << static_cast<int>(row.bPhysAddr[1]) << ":"
                          << static_cast<int>(row.bPhysAddr[2]) << ":"
                          << static_cast<int>(row.bPhysAddr[3]) << ":"
                          << static_cast<int>(row.bPhysAddr[4]) << ":"
                          << static_cast<int>(row.bPhysAddr[5]);
                return macStream.str();
            }
        }
    }
    return std::string();
}
