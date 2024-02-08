# Info Cat

一款**Windows平台**下可以获取部分烽火品牌（其它品牌自测）光猫工厂配置信息工具

## 使用

### 编译

0. **配置环境**  

   在Windows上配置好Flutter的开发环境

1. **克隆项目**  
   打开命令行或终端，运行以下命令以克隆仓库到本地机器：

   ```bash
   git clone https://github.com/CN-Scars/InfoCat.git
   ```

2. **进入项目目录**  
   使用命令行或终端进入项目目录：

   ```bash
   cd InfoCat
   ```

3. **获取依赖**  
   运行以下命令安装项目所需的依赖：

   ```bash
   flutter pub get
   ```

4. **运行项目**  
   在确保所有依赖都已成功安装后，使用以下命令编译并运行应用：
   
   ```bash
   flutter run -d windows
   ```

### 运行

编译完成后，一般会自动启动软件

![home_page](.\images\home_page.png)

### 操作

0. **连接网络**  开始操作前，先确保你的电脑通过Wi-Fi或者网线连接到光猫的网络中

1. **填写信息**
   填写光猫的网关地址信息

   ![gateway_address_information](.\images\gateway_address_information.png)

   如果愿意，可以选择开启“手动获取MAC地址”开关来手动填入光猫的MAC地址，如果关闭则会自动获取
   
   ![MAC_address_information](.\images\MAC_address_information.png)

2. **获取工厂配置**
   正常情况下，按下“连接到光猫”按钮后会自动获取到光猫的工厂配置，可以选择需要的配置项名称来查看其值
   ![factory_config_information](D:\Android\AndroidStudioProjects\InfoCat\images\factory_config_information.png)

## 注意事项

此工具的部分核心方法来源于[恩山](https://www.right.com.cn/forum/thread-8305036-1-1.html)和互联网，可能不具有通用性并存在时效性，故可以在遵循开源许可的情况下凭借对于您可用的方法来替换本示例工具的代码来客制化软件
