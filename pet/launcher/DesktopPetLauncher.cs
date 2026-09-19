using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Forms;

internal static class DesktopPetLauncher
{
    private const string PetMutexName = @"Local\CodexDesktopPetLauncher";
    private const string FaceManagerMutexName = @"Local\CodexDesktopPetFaceManager";

    [STAThread]
    private static int Main(string[] args)
    {
        var isFaceManager = args.Length > 0 &&
            string.Equals(args[0], "--face-manager", StringComparison.OrdinalIgnoreCase);
        var mutexName = isFaceManager ? FaceManagerMutexName : PetMutexName;
        var scriptName = isFaceManager ? "face-manager.ps1" : "desktop-pet.ps1";
        var windowTitle = isFaceManager ? "人脸管理" : "桌宠";

        bool createdNew;
        using (var mutex = new Mutex(true, mutexName, out createdNew))
        {
            if (!createdNew)
            {
                MessageBox.Show(
                    isFaceManager
                        ? "人脸管理窗口已经打开。"
                        : "桌面宠物已经在运行，请直接拖动桌面上的角色。",
                    windowTitle,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
                return 0;
            }

            var root = AppDomain.CurrentDomain.BaseDirectory;
            var scriptPath = Path.Combine(root, scriptName);
            if (!File.Exists(scriptPath))
            {
                MessageBox.Show(
                    "没有找到 " + scriptName + "，请保持快捷方式指向项目目录。",
                    windowTitle + "启动失败",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 2;
            }

            var powerShellPath = FindPowerShell();
            if (powerShellPath == null)
            {
                MessageBox.Show(
                    "没有找到 PowerShell，无法启动" + windowTitle + "。",
                    windowTitle + "启动失败",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 3;
            }

            var arguments =
                "-NoLogo -NoProfile -ExecutionPolicy Bypass -STA " +
                "-File \"" + scriptPath + "\"";

            var startInfo = new ProcessStartInfo
            {
                FileName = powerShellPath,
                Arguments = arguments,
                WorkingDirectory = root,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            try
            {
                using (var process = Process.Start(startInfo))
                {
                    if (process == null)
                    {
                        throw new InvalidOperationException("PowerShell process could not be created.");
                    }

                    var output = process.StandardOutput.ReadToEnd();
                    var error = process.StandardError.ReadToEnd();
                    process.WaitForExit();

                    if (process.ExitCode != 0)
                    {
                        var details = string.IsNullOrWhiteSpace(error) ? output : error;
                        MessageBox.Show(
                            windowTitle + "运行失败：\r\n\r\n" + details,
                            windowTitle + "启动失败",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error
                        );
                    }

                    return process.ExitCode;
                }
            }
            catch (Exception exception)
            {
                MessageBox.Show(
                    windowTitle + "运行失败：\r\n\r\n" + exception.Message,
                    windowTitle + "启动失败",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 4;
            }
        }
    }

    private static string FindPowerShell()
    {
        var fromPath = FindOnPath("pwsh.exe");
        if (!string.IsNullOrEmpty(fromPath))
        {
            return fromPath;
        }

        var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        var codexRuntimeRoot = Path.Combine(
            userProfile,
            @".cache\codex-runtimes"
        );
        var codexPowerShell = FindFile(
            codexRuntimeRoot,
            "pwsh.exe",
            7
        );
        if (!string.IsNullOrEmpty(codexPowerShell))
        {
            return codexPowerShell;
        }

        var programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        var programFilesPowerShell = Path.Combine(programFiles, @"PowerShell\7\pwsh.exe");
        if (File.Exists(programFilesPowerShell))
        {
            return programFilesPowerShell;
        }

        var localApps = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var windowsAppsPowerShell = Path.Combine(localApps, @"Microsoft\WindowsApps\pwsh.exe");
        if (File.Exists(windowsAppsPowerShell))
        {
            return windowsAppsPowerShell;
        }

        return FindOnPath("powershell.exe");
    }

    private static string FindOnPath(string fileName)
    {
        var pathVariable = Environment.GetEnvironmentVariable("PATH");
        if (string.IsNullOrEmpty(pathVariable))
        {
            return null;
        }

        foreach (var directory in pathVariable.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                var candidate = Path.Combine(directory.Trim(), fileName);
                if (File.Exists(candidate))
                {
                    return candidate;
                }
            }
            catch
            {
                // Ignore invalid PATH entries and continue searching.
            }
        }

        return null;
    }

    private static string FindFile(string root, string fileName, int depth)
    {
        if (depth < 0 || !Directory.Exists(root))
        {
            return null;
        }

        try
        {
            foreach (var candidate in Directory.GetFiles(root, fileName))
            {
                return candidate;
            }

            foreach (var directory in Directory.GetDirectories(root))
            {
                var found = FindFile(directory, fileName, depth - 1);
                if (!string.IsNullOrEmpty(found))
                {
                    return found;
                }
            }
        }
        catch
        {
            // Skip folders that are not accessible and continue searching.
        }

        return null;
    }
}
