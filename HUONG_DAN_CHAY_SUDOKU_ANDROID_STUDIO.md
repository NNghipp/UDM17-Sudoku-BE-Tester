# Hướng dẫn chạy Sudoku trên giả lập Android Studio và mở người chơi B

## 1. Các thành phần cần chạy

| Thành phần | Vai trò |
|---|---|
| Sudoku.Api | API đăng nhập, chạy tại `http://127.0.0.1:5243` trên máy tính. |
| Sudoku.Server | Server trận đấu, dùng TCP port `5000`. |
| Sudoku trên Android Emulator | Người chơi A. |
| Sudoku.Mobile trên Windows | Người chơi B để đấu thử với A. |

Source nằm ở `E:\prj_sudoku\UDM17-Sudoku`.

Android Studio cài tại `D:\android_studio`. Máy ảo đã chuẩn bị có tên hiển thị **Sudoku Local**, ID là `Sudoku_Local`.

Các đường dẫn ở tài liệu là vị trí trên máy đã kiểm thử. Nếu clone repository vào nơi khác, thay `E:\prj_sudoku\UDM17-Sudoku` bằng thư mục clone thực tế và điều chỉnh vị trí Android Studio/SDK.

Trên máy mới, cài môi trường .NET/MAUI và SQL Server theo README, cấu hình API rồi build backend và Windows client ở mục 5 trước khi chạy. Trong **Device Manager → Create Device**, chọn một cấu hình điện thoại, tải Android system image, đặt tên máy ảo là **Sudoku_Local**. Không cần chép máy ảo cũ vào GitHub.

Dự án dùng C#/.NET MAUI: Android Studio dùng để mở điện thoại giả lập; việc build ứng dụng thực hiện bằng .NET. Không cần tạo dự án Kotlin/Java hoặc chuyển source sang Android Studio.

## 2. Cách mở bằng Android Studio

### Bước 1 — Bật backend

Mở PowerShell và chạy nguyên khối sau. Nếu backend đã chạy thì không mở thêm bản trùng:

```powershell
Set-Location 'E:\prj_sudoku\UDM17-Sudoku'
$env:ASPNETCORE_ENVIRONMENT = 'Development'

if (!(Get-NetTCPConnection -LocalPort 5243 -State Listen -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath 'dotnet' `
        -ArgumentList 'E:\prj_sudoku\UDM17-Sudoku\Sudoku.Api\bin\Debug\net10.0\Sudoku.Api.dll','--urls','http://127.0.0.1:5243' `
        -WorkingDirectory 'E:\prj_sudoku\UDM17-Sudoku\Sudoku.Api' `
        -WindowStyle Hidden `
        -RedirectStandardOutput 'E:\prj_sudoku\outputs\android-local\api.log' `
        -RedirectStandardError 'E:\prj_sudoku\outputs\android-local\api-error.log'
}

if (!(Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath 'E:\prj_sudoku\UDM17-Sudoku\Sudoku.Server\bin\Debug\Sudoku.Server.exe' `
        -WorkingDirectory 'E:\prj_sudoku\UDM17-Sudoku' -WindowStyle Hidden
}
```

Hai dịch vụ chạy nền nên không nhất thiết có cửa sổ hiện ra. Kiểm tra:

```powershell
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalPort -in 5000,5243 } |
    Select-Object LocalAddress,LocalPort,OwningProcess
```

Kết quả phải có cả port `5000` và `5243`.

### Bước 2 — Mở điện thoại giả lập

1. Mở `D:\android_studio\bin\studio64.exe`.
2. Ở màn hình Welcome, chọn **More Actions → Virtual Device Manager**. Nếu đang mở một project, vào **Tools → Device Manager**.
3. Tìm **Sudoku Local**, nhấn nút **▶** để khởi động.
4. Chờ điện thoại vào màn hình chính. Lần khởi động lạnh có thể mất vài phút.
5. Mở danh sách ứng dụng trên điện thoại, chọn **Sudoku.Mobile**.

Ứng dụng đã được cài trên máy ảo này. Nếu không thấy biểu tượng, kéo file APK sau từ File Explorer thả vào cửa sổ giả lập, chờ cài xong rồi mở app:

```text
E:\prj_sudoku\outputs\android-local\com.companyname.sudoku.mobile-Signed.apk
```

Dùng APK trong `android-local`; APK trong `browserstack` có cấu hình kết nối khác. Nếu vừa clone từ GitHub và chưa tự build APK, dùng file **`apk\Sudoku.Mobile-Signed.apk`** nằm trong repository.

### Bước 3 — Đăng nhập người chơi A trên Android

| Trường | Giá trị |
|---|---|
| Username | `test_player_a` |
| Password | `SudokuTest!2026` |

Nhấn **Login & Play!**. Đăng nhập thành công sẽ vào Lobby có nút **FIND OPPONENT**.

### Bước 4 — Mở client test B trên Windows

Chạy trong PowerShell:

```powershell
Start-Process -FilePath 'E:\prj_sudoku\UDM17-Sudoku\Sudoku.Mobile\bin\Debug\net10.0-windows10.0.19041.0\win-x64\Sudoku.Mobile.exe' `
    -ArgumentList '--dev-player=test_player_b','--dev-quick-match' `
    -WorkingDirectory 'E:\prj_sudoku\UDM17-Sudoku'
```

Client B sẽ mở cửa sổ Windows, tự đăng nhập `test_player_b` và tìm trận. Chờ cửa sổ vào Lobby/tìm đối thủ trước khi thao tác tiếp. Chỉ mở một client B cho tài khoản này.

Nếu mở app Windows thủ công không có tham số, đăng nhập `test_player_b` / `SudokuTest!2026`, rồi nhấn **FIND OPPONENT**.

Các tham số tự đăng nhập/tìm trận chỉ hoạt động với bản Windows **Debug** đã build.

### Bước 5 — Bắt cặp và chơi

1. Trên Android A, nhấn **FIND OPPONENT**.
2. Chờ A và B bắt cặp, cả hai chuyển vào cùng trận Sudoku.
3. A đi một nước trên Android; kiểm tra B nhận tiến độ mới.
4. B đi một nước trên Windows; kiểm tra A nhận tiến độ mới.

Nếu chọn **JOIN** vào phòng thay vì Quick Match, có thể xuất hiện màn hình chuẩn bị. Khi đó nhấn **I'M READY** ở phía chưa sẵn sàng. Không để quá lâu vì server có giới hạn thời gian chờ chuẩn bị trận.

Nếu B đã ngừng tìm trận do hết thời gian chờ, thực hiện lại **FIND OPPONENT** trên B và A.

## 3. Cách mở nhanh bằng script

Thay cho việc mở máy ảo thủ công, chạy trong PowerShell:

```powershell
Set-Location 'E:\prj_sudoku\UDM17-Sudoku'
.\testing\Start-Android.ps1
```

Script tự bật backend, mở giả lập ở port `5556` và mở Sudoku. APK chỉ được cài khi ứng dụng chưa có hoặc khi yêu cầu `-Reinstall`. Sau đó đăng nhập A rồi mở B bằng lệnh ở Bước 4.

Sau khi build APK mới, chạy:

```powershell
.\testing\Start-Android.ps1 -Reinstall
```

Đóng các giả lập khác trước khi chạy script. Script chờ thêm 30 giây sau khi máy ảo mới boot; nếu dịch vụ cài đặt chưa sẵn sàng, đợi một phút rồi thử lại. Cấu hình giả lập hiện dùng 2 CPU, GPU software và không nạp/lưu snapshot.

Chọn một trong hai cách khởi động máy ảo. Nếu đã chạy **Sudoku Local** bằng nút ▶ trong Android Studio, không chạy tiếp script để tránh mở cùng máy ảo lần nữa ở port khác.

## 4. Lỗi thường gặp

| Hiện tượng | Cách kiểm tra |
|---|---|
| Không kết nối được máy chủ | Kiểm tra cả hai port `5243` và `5000`; dùng APK trong `android-local`. |
| Đăng nhập sai | Dùng đúng username và mật khẩu ở trên; chú ý dấu `!`, chữ hoa và khoảng trắng thừa. |
| Không tìm thấy đối thủ | A và B phải dùng hai tài khoản khác nhau, cùng backend và cùng tìm trận. |
| Báo đã có phiên hoạt động | Kiểm tra có client cũ đang dùng cùng tài khoản không; đóng client cũ trước khi đăng nhập lại. |
| Máy ảo báo đang chạy/khóa | Không mở cùng AVD từ cả script và Device Manager. Kiểm tra cửa sổ giả lập đang mở. |
| Không thấy thay đổi code mới | Cần build lại và cài lại APK; APK không tự thay đổi theo source. |

Android Emulator dùng `10.0.2.2` để truy cập máy tính: API là `http://10.0.2.2:5243/`, game TCP là `10.0.2.2:5000`. Windows B dùng `127.0.0.1`. Không cần BrowserStack hoặc tunnel.

## 5. Build lại sau khi sửa source

```powershell
Set-Location 'E:\prj_sudoku\UDM17-Sudoku'

dotnet build .\Sudoku.Api\Sudoku.Api.csproj
dotnet build .\Sudoku.Server\Sudoku.Server.csproj

dotnet publish .\Sudoku.Mobile\Sudoku.Mobile.csproj `
    -f net10.0-android -c Release `
    -p:BrowserStack=false -p:AndroidPackageFormats=apk `
    -p:AndroidSdkDirectory=C:\Users\ngong\AppData\Local\Android\Sdk `
    -o E:\prj_sudoku\outputs\android-local

dotnet build .\Sudoku.Mobile\Sudoku.Mobile.csproj `
    -f net10.0-windows10.0.19041.0 -c Debug -p:BrowserStack=false
```

Sau khi build, cài lại APK bằng cách kéo thả vào giả lập hoặc dùng script ở mục 3. Nếu backend đang chạy, cần tắt và khởi động lại backend để nạp bản mới.

## 6. Khi kiểm thử xong

Đóng client Windows B, đóng cửa sổ giả lập và dừng hai tiến trình backend của dự án. Android Studio có thể để mở cho lần sau. Trạng thái phòng/trận trên game server hiện lưu trong bộ nhớ, nên tắt server sẽ mất các phòng/trận đang chạy.
