@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo Final Encoding Fixed File Rename Tool (Descending Order)
echo ======================================================

if not exist "qianziwen.txt" (
    echo Error: qianziwen.txt not found
    echo Please make sure the qianziwen.txt file exists in the current directory
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: 使用PowerShell直接读取千字文文件内容（确保正确编码）
for /f "delims=" %%a in ('powershell -command "& {[System.IO.File]::ReadAllText('qianziwen.txt', [System.Text.Encoding]::UTF8)}" 2^>nul') do set "QZW=%%a"

:: 检查是否成功读取千字文
if not defined QZW (
    echo Error: Failed to read qianziwen.txt
    echo This might be due to encoding issues or file access problems
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: 显示前几个字符以验证读取成功
echo Successfully read qianziwen.txt

:: 初始化计数器和统计变量
set counter=1
set success_count=0
set error_count=0

echo.
echo Collecting files...
echo.

:: 创建临时文件列表
set temp_list=%temp%\file_list_%random%.txt
if exist "%temp_list%" del "%temp_list%"

:: 收集所有要处理的文件（按大小排序，降序）
for /f "tokens=*" %%f in ('dir /b /a-d /o-s-') do (
    set "process_file=1"
    
    :: 排除所有批处理文件
    if /i "%%~xf"==".bat" set process_file=0
    
    :: 排除所有PowerShell脚本文件
    if /i "%%~xf"==".ps1" set process_file=0
    
    :: 排除特定的重要文件
    if /i "%%~nxf"=="qianziwen.txt" set process_file=0
    if /i "%%~nxf"=="final_encoding_fixed_rename_desc.bat" set process_file=0
    
    if !process_file! equ 1 (
        echo "%%f" >> "%temp_list%"
    )
)

echo Processing files...
echo.

:: 处理文件列表
if exist "%temp_list%" (
    for /f "delims=" %%g in ('type "%temp_list%"') do (
        :: 去除引号
        set "filename=%%g"
        set "filename=!filename:"=!"
        
        echo Processing: "!filename!"
        
        :: 检查文件是否存在
        if exist "!filename!" (
            :: 获取文件扩展名
            for %%x in ("!filename!") do set "file_ext=%%~xx"
            
            :: 确保计数器是正数
            if !counter! lss 1 set counter=1
            
            :: 生成4位数字编号
            set "num=000!counter!"
            set "num=!num:~-4!"
            
            :: 计算千字文位置（确保非负数）
            set /a "index=!counter! - 1"
            if !index! lss 0 set index=0
            
            set /a "pos1=!index! * 2"
            set /a "pos2=!index! * 2 + 1"
            
            echo Counter: !counter!, Positions: !pos1! and !pos2!
            
            set "char1="
            set "char2="
            set "suffix="
            
            :: 使用PowerShell获取千字文字符（确保正确处理中文编码）
            for /f "delims=" %%c in ('powershell -command "& {try { $chars = '%QZW%'; if ($chars.Length -gt !pos1! -and $chars.Length -gt !pos2!) { $c1 = $chars.Substring(!pos1!, 1); $c2 = $chars.Substring(!pos2!, 1); Write-Output \"$c1`n$c2\" } else { Write-Output \"X`nX\" } } catch { Write-Output \"X`nX\" }}" 2^>nul') do (
                if not defined char1 (
                    set "char1=%%c"
                ) else (
                    set "char2=%%c"
                )
            )
            
            :: 设置后缀
            if defined char1 if defined char2 (
                set "suffix=!char1!!char2!"
            ) else (
                set "suffix=XX"
            )
            
            echo Got suffix: "!suffix!"
            
            :: 新文件名：数字编号+千字文后缀+原扩展名
            set "new_name=!num!!suffix!!file_ext!"
            
            :: 清理文件名中的特殊字符
            set "new_name=!new_name:"=!"
            
            echo New name: "!new_name!"
            
            :: 第一步：重命名为临时名称(tbd)
            set "temp_name=tbd_!num!!file_ext!"
            echo Step 1: Renaming "!filename!" to temporary name "!temp_name!"
            ren "!filename!" "!temp_name!" 2>nul
            
            if errorlevel 1 (
                echo Error: Failed to rename "!filename!" to "!temp_name!"
                set /a error_count+=1
            ) else (
                :: 第二步：重命名为最终名称
                echo Step 2: Renaming "!temp_name!" to "!new_name!"
                ren "!temp_name!" "!new_name!" 2>nul
                
                if errorlevel 1 (
                    echo Error: Failed to rename "!temp_name!" to "!new_name!"
                    set /a error_count+=1
                ) else (
                    echo Success: "!filename!" -^> "!new_name!"
                    set /a success_count+=1
                )
            )
        ) else (
            echo Error: File "!filename!" does not exist
            set /a error_count+=1
        )
        
        set /a counter+=1
        echo.
    )
    
    :: 删除临时文件
    if exist "%temp_list%" del "%temp_list%"
)

echo.
echo Process completed!
echo Successfully renamed: %success_count% files
echo Failed: %error_count% files
echo.
echo Press any key to exit...
pause >nul