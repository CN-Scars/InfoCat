#ifndef GET_FACTORY_CONFIG_H_
#define GET_FACTORY_CONFIG_H_

#define _WINSOCK_DEPRECATED_NO_WARNINGS

#include <winsock2.h>
#include <windows.h>
#include <string>
#include <unordered_map>

using CONFIG_DATA = std::unordered_map<std::string, std::string>;

int send_command(SOCKET s, const std::string &command);

void wait_for_prompt(SOCKET s, const std::string &prompt);

CONFIG_DATA parse_and_store_data(const std::string &data);

CONFIG_DATA receive_data(SOCKET s);

CONFIG_DATA getFactoryConfig(const std::string &gatewayAddress);

#endif // GET_FACTORY_CONFIG_H_
