#include "flutter_window.h"
#include "gateway_mac_finder.h"

#include <optional>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>
#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void ConfigureMethodChannel(flutter::FlutterEngine *engine)
{
    auto method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        engine->messenger(), "GetGatewayMACAddress",
        &flutter::StandardMethodCodec::GetInstance());

    method_channel->SetMethodCallHandler(
        [](const auto &call, auto result)
        {
            if (call.method_name().compare("getGatewayMACAddress") == 0)
            {
                const auto *arguments = std::get_if<flutter::EncodableMap>(call.arguments());
                if (!arguments)
                {
                    result->Error("Bad Arguments", "Expected arguments to be a map");
                    return;
                }
                if (arguments->find(flutter::EncodableValue("gatewayAddress")) ==
                    arguments->end())
                {
                    result->Error("Missing argument", "Expected gatewayAddress");
                    return;
                }
                const auto &gatewayAddressValue = arguments->at(
                    flutter::EncodableValue("gatewayAddress"));
                if (!std::holds_alternative<std::string>(gatewayAddressValue))
                {
                    result->Error("Invalid argument", "Expected string for gatewayAddress");
                    return;
                }
                std::string gatewayAddress = std::get<std::string>(gatewayAddressValue);
                std::string response = getGatewayMACAddress(gatewayAddress);
                result->Success(flutter::EncodableValue(response));
            }
            else
            {
                result->NotImplemented();
            }
        });
}

bool FlutterWindow::OnCreate()
{
    if (!Win32Window::OnCreate())
    {
        return false;
    }

    RECT frame = GetClientArea();

    // The size here must match the window dimensions to avoid unnecessary surface
    // creation / destruction in the startup path.
    flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
        frame.right - frame.left, frame.bottom - frame.top, project_);
    // Ensure that basic setup of the controller was successful.
    if (!flutter_controller_->engine() || !flutter_controller_->view())
    {
        return false;
    }
    RegisterPlugins(flutter_controller_->engine());
    SetChildContent(flutter_controller_->view()->GetNativeWindow());

    flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                        { this->Show(); });

    // Flutter can complete the first frame before the "show window" callback is
    // registered. The following call ensures a frame is pending to ensure the
    // window is shown. It is a no-op if the first frame hasn't completed yet.
    flutter_controller_->ForceRedraw();

    ConfigureMethodChannel(flutter_controller_->engine());
    return true;
}

void FlutterWindow::OnDestroy()
{
    if (flutter_controller_)
    {
        flutter_controller_ = nullptr;
    }

    Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam)

    noexcept
{
    // Give Flutter, including plugins, an opportunity to handle window messages.
    if (flutter_controller_)
    {
        std::optional<LRESULT> result =
            flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                          lparam);
        if (result)
        {
            return *result;
        }
    }

    switch (message)
    {
    case WM_FONTCHANGE:
        flutter_controller_->engine()->ReloadSystemFonts();
        break;
    }

    return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
