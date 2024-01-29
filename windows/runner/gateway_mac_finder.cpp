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
    // 第一次调用，获取缓冲区大小
    GetIpNetTable(nullptr, &bufferSize, FALSE);

    std::vector<unsigned char> buffer(bufferSize);

    // 获取ARP表
    if (GetIpNetTable(reinterpret_cast<PMIB_IPNETTABLE>(buffer.data()), &bufferSize, FALSE) ==
        NO_ERROR)
    {
        auto arpTable = reinterpret_cast<PMIB_IPNETTABLE>(buffer.data());

        // 遍历ARP表
        for (int i = 0; i < static_cast<int>(arpTable->dwNumEntries); ++i)
        {
            auto &row = arpTable->table[i];
            in_addr addr;   // IPv4地址结构体
            inet_pton(AF_INET, gatewayAddress.c_str(), &addr);  // 将字符串IP地址转换为in_addr结构体
            if (row.dwAddr == addr.S_un.S_addr) // 检查是否是网关地址
            {
                // 将MAC地址转换为字符串
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
    // 没有找到网关的MAC地址
    return std::string();
}
