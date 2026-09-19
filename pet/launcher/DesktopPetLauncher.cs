using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Forms;

internal static class DesktopPetLauncher
{
    private const string MutexName = @"Local\CodexDesktopPetLauncher";

    [STAThread]
    private static int Main()
    {
        bool createdNew;
        using (var mutex = new Mutex(true, MutexName, out createdNew))
        {
            if (!createdNew)
            {
                MessageBox.Show(
                    "桌面宠物已经在运行，请直接拖动桌面上的角色。",
                    "桌宠",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );
                return 0;
            }

            var root = AppDomain.CurrentDomain.BaseDirectory;
            var scriptPath = Path.Combine(root, "desktop-pet.ps1");
            if (!File.Exists(scriptPath))
            {
                MessageBox.Show(
                    "没有找到 desktop-pet.ps1，请保持快捷方式指向项目目录。",
                    "桌宠启动失败",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 2;
            }

            var powerShellPath = FindPowerShell();
            if (powerShellPath == null)
            {
                MessageBox.Show(
                    "没有找到 PowerShell，无法启动桌宠。",
                    "桌宠启动失败",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 3;
            }

            var arguments =
                "-NoLogo -NoProfile -ExecutionPolicy Bypass -STA " +
                "-WindowStyle Hidden -File \"" + scriptPath + "\"";

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
                            "桌宠运行失败：\r\n\r\n" + details,
                            "桌宠启动失败",
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
                    "桌宠运行失败：\r\n\r\n" + exception.Message,
                    "桌宠启动失败",
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
}
