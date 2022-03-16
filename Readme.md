#1.编译版本
-- 7.82.0

#2.编译
-- 直接运行脚本即可 sh <脚本路径>
-- build_ios_active.sh 支持架构（arm64 x86_64）
-- build_ios_all.sh 支持架构（armv7 armv7s arm64 i386 x86_64）
-- 修改最低支持版本号请修改'IPHONEOS_DEPLOYMENT_TARGET'字段值
-- 如需编译其他版本请替换resource文件夹

#3.注意
-- 使用需添加依赖库libz.tbd
-- Apple架构在模拟器运行需要在Build Settings --> Excluded Architectures --> Debug和Release下添加 Any iOS Simulator SDK 字段，值为arm64，可参考demo配置

#4.参考
-- 参考自https://github.com/gcesarmza/curl-android-ios

#5.官方资源文件地址
-- https://curl.se/download.html
