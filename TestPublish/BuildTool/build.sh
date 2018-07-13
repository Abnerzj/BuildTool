
# 使用方法
# step1 : 将BuildTool整个文件夹复制到项目主目录,项目主目录,项目主目录(重要的事情说3遍!),注意是复制！不是拖入项目主目录，因为苹果审核有屏蔽fir关键词。
# step2 : 打开build.sh文件, 修改 "项目自定义部分" 配置好项目参数
# step3 : 打开终端, cd到BuildTool文件夹 (ps:在终端中先输入cd, 直接拖入BuildTool文件夹, 回车)
# step4 : 输入 sh build.sh 命令, 回车, 开始执行此打包脚本。

# 功能概述
# 1.支持多个Target的项目构建。
# 2.发布平台：AppStore、蒲公英、fir
# 3.项目类型：支持project和workspace项目。
# 4.支持一键构建并发布Debug包到蒲公英平台。
# 5.遗留：上传到蒲公英平台更新说明里面加上"\n"，在应用下载页面看不到换行效果，如果有了解的小伙伴请Issues我。

# 联系作者
# GitHub：https://github.com/Abnerzj/BuildTool
# 简书：https://www.jianshu.com/p/4ebd32d22240

# ===============================项目自定义部分(自定义好下列参数后再执行该脚本)============================= #
# 第一部分：项目设置
# 1.构建的Target。一个项目存在多个环境，同时对应多个Target，比如生产环境、开发环境等。开发环境值为1、其他值为生产环境。
# PS：如果还有其他环境，可以定义相应的值区分，该变量主要方便对一个项目中存在多个Target的时候打包。
build_target=0
# 2.打包模式：Debug/Release。
build_mode=Debug
# 3.打Debug包是否默认发布到蒲公英。如果需要选择发布到fir或蒲公英两个平台，需设置为0。
build_mode_debug_default_publish_pgy=1
# 4.更新说明。打Debug包发布到蒲公英是否需要添加更新说明，为0则直接使用publish_pgy_updatedesc中内容作为更新说明。
publish_pgy_need_updatedesc=0
publish_pgy_updatedesc="1.需要添加更新说明 \n 2.需要添加更新说明\n3.需要添加更新说明\n"
# 5.项目是否使用到cocoaPod，没使用cocoaPod需设置为0
project_use_cocoaPod=0

# 第二部分：平台信息设置
# 1.苹果开发者帐号的用户名和密码，如果上传到AppStore需要设置。
AppleID_user_name=xxx
AppleID_user_pwd=xxx

# 2.蒲公英平台，如果发布到蒲公英需要设置。
pgy_api_key=xxx
pgy_user_key=xxx
# 应用在蒲公英页面的url的短链名。比如https://www.pgyer.com/dangdang，短链名就是dangdang
pgy_app_url_shortcut="xxx"

# 3.fir平台的token，如果发布到fir需要设置。
fir_token=xxx

# ===============================自动打包部分(无特殊情况不用修改)============================= #
# 1.构建开始时间：秒
build_start_time=$(date +%s)
# 当前时间:2018-01-03-12:02:46
currentDate=$(date +%Y-%m-%d-%H-%M-%S)

# 2.进入当前Shell程序的目录，得到shell文件绝对路径。
shellfile_path=$(cd `dirname $0`; pwd)
# 返回上层目录（项目主目录）
cd ..

# 3.项目主目录绝对路径
project_path=$(pwd)

# 4.项目运行文件类型名、项目运行文件类型扩展名。PS：用cocoaPod和不用cocoaPod时，打开项目的文件名和文件类型。
project_runfile_type_name=project
project_runfile_ext_name=xcodeproj
if [ $project_use_cocoaPod == 1 ];
then
project_runfile_type_name=workspace
project_runfile_ext_name=xcworkspace
fi

# 5.获取工程名/项目名。
project_name=`find . -name *.$project_runfile_ext_name | awk -F "[/.]" '{print $(NF-1)}'`
# 6.scheme名。PS：一般生成环境Target名跟工程名一样，我这里直接用的是Target名，不同可以自行修改。
scheme_name=${project_name}
# 7.构件开发环境Target时一些参数调整，我这里设置了scheme_name和pgy_app_url_shortcut，是直接在后面拼接"-test"，不同可以自行修改。
if [ $build_target == 1 ];
then
scheme_name=${scheme_name}-test
pgy_app_url_shortcut=${pgy_app_url_shortcut}-test
fi

# 8.工程中Target对应的配置plist文件名称、版本号、内部版本号、bundleID。Xcode默认的配置文件为Info.plist，如果有自定义用下面一行。
#info_plist_path="$project_name/${scheme_name}-Info.plist"
info_plist_path="$project_name/Info.plist"
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $info_plist_path`
bundle_build_version=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $info_plist_path`
bundle_identifier=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $info_plist_path`

# 9.导出plist配置文件所在路径
exportOptionsPlistPath=${shellfile_path}/AdHocExportOptions.plist

# 10.默认打Debug包
if [ $build_mode == "Debug" ];
then
exportOptionsPlistPath=${shellfile_path}/AdHocExportOptions.plist
# 打Debug包时，删除旧.xcarchive文件
rm -rf ${project_path}/build/XcarchiveDir/${scheme_name}/${build_mode}/*

# 选择发布类型
else

echo "\033[36;1mPlease enter the number you want to export ? [ 1:app-store 2:ad-hoc] \033[0m"

## 获取用户选择的发布类型
read number
while([[ $number != 1 ]] && [[ $number != 2 ]])
do
echo "\033[36;1mError! Should enter 1 or 2 \033[0m"
echo "\033[36;1mPlease enter the number you want to export ? [ 1:app-store 2:ad-hoc] \033[0m"
read number
done

    #app-store
    if [ $number == 1 ];
    then
    build_mode=Release
    exportOptionsPlistPath=${shellfile_path}/AppStoreExportOptions.plist

    #ad-hoc
    else
    build_mode=Debug
    exportOptionsPlistPath=${shellfile_path}/AdHocExportOptions.plist
    rm -rf ${project_path}/build/XcarchiveDir/${scheme_name}/${build_mode}/*
    fi
fi

# 11.build文件夹路径
build_path=${project_path}/build/XcarchiveDir/${scheme_name}/${build_mode}/${currentDate}/
# 导出.ipa文件所在路径:当前根路径/build/IPADir/target名/打包模式/当前时间/ipa等文件
exportIpaPath=${project_path}/build/IPADir/${scheme_name}/${build_mode}/${currentDate}

# 12.发布到蒲公英的更新说明
if [ $publish_pgy_need_updatedesc == 1 ];
then
## 获取用户输入的更新说明
echo "\033[36;1mPlease enter the update desc for upload pgy! \033[0m"
read publish_pgy_updatedesc
#read -p "Please enter the update desc for upload pgy!" publish_pgy_updatedesc
fi

# 13.开始Build
echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean -configuration ${build_mode} -quiet  || exit


echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${build_mode}
echo '///-----------'
xcodebuild \
archive -${project_runfile_type_name} ${project_path}/${project_name}.${project_runfile_ext_name} \
-scheme ${scheme_name} \
-configuration ${build_mode} \
-archivePath ${build_path}/${project_name}.xcarchive -quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

sleep 10

# 输出编译总用时
build_end_time=$(date +%s)
echo "\n\n"
echo "\033[36;1m编译总用时: $(( $build_end_time - $build_start_time ))s \033[0m"

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${build_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ];
then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///-----------='
echo ''

echo '///-------------'
echo '/// 开始发布ipa包 '
echo '///-------------'

# 14.发布到不同平台
if [ $build_mode != "Debug" ];
    then

    #验证并上传到App Store
    echo "\033[32m *************************  开始上传appStore，请稍后。。。  *************************  \033[0m"
    altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
    "$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u ${AppleID_user_name} -p ${AppleID_user_pwd} -t ios --output-format xml
    "$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u ${AppleID_user_name} -p ${AppleID_user_pwd} -t ios --output-format xml
    echo "\033[32m *************************  上传appStore成功  *************************  \033[0m"
    open https://itunesconnect.apple.com/
else

    #默认发布到蒲公英
    if [ $build_mode_debug_default_publish_pgy == 1 ];
        then
        #上传到蒲公英
        echo "\033[32m *************************  开始上传蒲公英，请稍后。。。  *************************  \033[0m"
        curl -F "file=@${exportIpaPath}/${scheme_name}.ipa" -F "uKey=${pgy_user_key}" -F "_api_key=${pgy_api_key}" -F "updateDescription=${publish_pgy_updatedesc}" -F "installType=1" https://qiniu-storage.pgyer.com/apiv1/app/upload
        echo "\033[32m \n\n上传到蒲公英完毕,打开应用网页 \033[0m"
        open https://www.pgyer.com/${pgy_app_url_shortcut}
    else

        ## 选择发布平台
        echo "\033[36;1mPlease enter the number you want to export ? [ 1:fir 2:蒲公英] \033[0m"

        read platform
        while([[ $platform != 1 ]] && [[ $platform != 2 ]])
        do
        echo "\033[36;1mError! Should enter 1 or 2 \033[0m"
        echo "\033[36;1mPlease enter the number you want to export ? [ 1:fir 2:蒲公英] \033[0m"
        read platform
        done

        ## 判断选择的发布平台
        if [ $platform == 1 ];
            then
            #上传到Fir
            fir login -T ${fir_token}
            fir publish $exportIpaPath/$scheme_name.ipa
        else
            #上传到蒲公英
            echo "\033[32m *************************  开始上传蒲公英，请稍后。。。  *************************  \033[0m"
            curl -F "file=@${exportIpaPath}/${scheme_name}.ipa" -F "uKey=${pgy_user_key}" -F "_api_key=${pgy_api_key}" -F "updateDescription=${publish_pgy_updatedesc}" -F "installType=1" https://qiniu-storage.pgyer.com/apiv1/app/upload
            echo "\033[32m \n\n上传到蒲公英完毕,打开应用网页 \033[0m"
            open https://www.pgyer.com/${pgy_app_url_shortcut}
        fi
    fi
fi
echo "\n\n"

# 15.输出打包总用时
build_end_time=$(date +%s)
echo "\033[36;1m打包总用时: $(( $build_end_time - $build_start_time ))s \033[0m"
echo "已运行完毕>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
exit 0


