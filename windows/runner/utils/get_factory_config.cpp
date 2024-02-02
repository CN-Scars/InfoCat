#include "get_factory_config.h"

#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>

#pragma comment(lib, "Ws2_32.lib") // 加载 Winsock 库

using CONFIG_DATA = std::unordered_map<std::string, std::string>;

int send_command(SOCKET s, const std::string &command)
{
    if (send(s, command.c_str(), static_cast<int>(command.length()), 0) < 0)
    {
        std::cerr << "发送失败 : " << WSAGetLastError() << std::endl;
        return 1;
    }
    return 0;
}

void wait_for_prompt(SOCKET s, const std::string &prompt)
{
    char buffer[1024];
    std::string data;
    size_t size;

    std::cout << "等待提示..." << std::endl;
    while (true)
    {
        size = recv(s, buffer, 1023, 0);
        if (size > 0)
        {
            buffer[size] = '\0';
            data += buffer;

            // 在收到的数据中查找提示
            if (data.find(prompt) != std::string::npos)
            {
                std::cout << "已收到提示" << prompt << std::endl;
                break;
            }
        }
        else
        {
            // 错误或连接断开
            std::cerr << "接收失败或连接断开" << std::endl;
            break;
        }
    }
}

CONFIG_DATA parse_and_store_data(const std::string &data)
{
    CONFIG_DATA configMap;
    std::istringstream iss(data);
    std::string line;
    while (std::getline(iss, line))
    {
        size_t pos = line.find('=');
        if (pos != std::string::npos)
        {
            std::cout << "当前行：" << line << std::endl;

            // 过滤掉不包含任何键或值的行
            std::string key = line.substr(0, pos);
            std::string value = line.substr(pos + 1);
            if (!key.empty() || !value.empty())
            {
                configMap[key] = value;
                std::cout << "已存储：" << key << " : " << value << std::endl;
            }
        }
    }

    std::cout << "解析完成" << std::endl;
    return configMap;
}

CONFIG_DATA receive_data(SOCKET s)
{
    char buffer[4096];
    size_t size;
    std::string data;

    std::cout << "开始接收数据..." << std::endl;

    while ((size = recv(s, buffer, 4095, 0)) > 0)
    {
        buffer[size] = '\0';

        // 判断buffer末尾是否含有“/var #”
        if (buffer[size - 2] == '#' && buffer[size - 3] == ' ')
        {
            data = buffer;
            break;
        }
    }

    return parse_and_store_data(data);
}

CONFIG_DATA getFactoryConfig(const std::string &gatewayAddress)
{
    WSADATA wsa;
    SOCKET s;
    struct sockaddr_in server;

    std::cout << "初始化 Winsock..." << std::endl;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
    {
        std::cout << "失败。错误代码 : " << WSAGetLastError() << std::endl;
        return CONFIG_DATA();
    }

    std::cout << "初始化成功。" << std::endl;

    // 创建一个 socket
    if ((s = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET)
    {
        std::cout << " : 无法创建 socket" << WSAGetLastError() << std::endl;
        return CONFIG_DATA();
    }

    std::cout << "Socket 创建成功。" << std::endl;

    server.sin_addr.s_addr = inet_addr(gatewayAddress.c_str());
    server.sin_family = AF_INET;
    server.sin_port = htons(23); // Telnet 端口是 23

    // 连接到远程服务器
    if (connect(s, (struct sockaddr *)&server, sizeof(server)) < 0)
    {
        std::cerr << "连接错误" << std::endl;
        return CONFIG_DATA();
    }

    std::cout << "已连接" << std::endl;

    // 等待登录提示
    wait_for_prompt(s, "login:");
    send_command(s, "root\r\n");
    std::cout << "已传输用户名" << std::endl;

    // 等待密码提示
    wait_for_prompt(s, "Password:");
    send_command(s, "hg2x0\r\n");
    std::cout << "已传输密码" << std::endl;

    // 发送命令并接收数据
    send_command(s, "cat /flash/cfg/agentconf/factory.conf\r\n");
    auto configMap = receive_data(s);

    // 发送退出命令
    if (!send_command(s, "exit\r\n"))
        std::cout << "退出成功" << std::endl;
    else
        std::cout << "退出失败" << std::endl;

    // 关闭 socket
    closesocket(s);
    WSACleanup();

    return configMap;
}
