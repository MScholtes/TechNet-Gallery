# Author: Markus Scholtes, 2017/05/08
# Version 2.18 - changes for Win 11 3085 and up, 2024/02/15

# prefer $PSVersionTable.BuildVersion to [Environment]::OSVersion.Version
# since a wrong Windows version might be returned in RunSpaces
if ($PSEdition -eq "Desktop")
{ # Windows Powershell
	$OSVer = $PSVersionTable.BuildVersion.Major
	$OSBuild = $PSVersionTable.BuildVersion.Build
}
else
{ # Powershell Core
	$OSVer = [Environment]::OSVersion.Version.Major
	$OSBuild = [Environment]::OSVersion.Version.Build
}

if ($OSVer -lt 10)
{
	Write-Error "Windows 10 or above is required to run this script"
	exit -1
}

if ($OSBuild -lt 14393)
{
	Write-Error "Windows 10 1607 or above is required to run this script"
	exit -1
}


Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;

namespace VirtualDesktop
{
	#region Type definitions
	// define HString on .Net 5 / overwrite HString on .Net 4 - https://github.com/dotnet/runtime/issues/39827
	[StructLayout(LayoutKind.Sequential)]
	public struct HString : IDisposable
	{
		private readonly IntPtr handle;
		public static HString FromString(string s)
		{
			var h = Marshal.AllocHGlobal(IntPtr.Size);
			Marshal.ThrowExceptionForHR(WindowsCreateString(s, s.Length, h));
			return Marshal.PtrToStructure<HString>(h);
		}

		public void Delete()
		{
			WindowsDeleteString(handle);
		}

		[DllImport("api-ms-win-core-winrt-string-l1-1-0.dll", CallingConvention = CallingConvention.StdCall)]
		private static extern int WindowsCreateString([MarshalAs(UnmanagedType.LPWStr)] string sourceString, int length, [Out] IntPtr hstring);

		[DllImport("api-ms-win-core-winrt-string-l1-1-0.dll", CallingConvention = CallingConvention.StdCall, ExactSpelling = true)]
		private static extern int WindowsDeleteString(IntPtr hstring);

		[DllImport("api-ms-win-core-winrt-string-l1-1-0.dll", CallingConvention = CallingConvention.StdCall, ExactSpelling = true, CharSet = CharSet.Unicode)]
		private static extern IntPtr WindowsGetStringRawBuffer(HString hString, IntPtr length);

		public void Dispose()
		{
			Delete();
		}

		public static implicit operator string(HString hString)
		{
			var str = Marshal.PtrToStringUni(WindowsGetStringRawBuffer(hString, IntPtr.Zero));
			hString.Delete();
			if (null != str)
				return str;
			else
				return string.Empty;
		}
	}
	#endregion

	#region COM API
	internal static class Guids
	{
		public static readonly Guid CLSID_ImmersiveShell = new Guid("C2F03A33-21F5-47FA-B4BB-156362A2F239");
		public static readonly Guid CLSID_VirtualDesktopManagerInternal = new Guid("C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B");
		public static readonly Guid CLSID_VirtualDesktopManager = new Guid("AA509086-5CA9-4C25-8F95-589D3C07B48A");
		public static readonly Guid CLSID_VirtualDesktopPinnedApps = new Guid("B5A399E7-1C87-46B8-88E9-FC5747B171BD");
	}

	[StructLayout(LayoutKind.Sequential)]
	internal struct Size
	{
		public int X;
		public int Y;
	}

	[StructLayout(LayoutKind.Sequential)]
	internal struct Rect
	{
		public int Left;
		public int Top;
		public int Right;
		public int Bottom;
	}

	internal enum APPLICATION_VIEW_CLOAK_TYPE : int
	{
		AVCT_NONE = 0,
		AVCT_DEFAULT = 1,
		AVCT_VIRTUAL_DESKTOP = 2
	}

	internal enum APPLICATION_VIEW_COMPATIBILITY_POLICY : int
	{
		AVCP_NONE = 0,
		AVCP_SMALL_SCREEN = 1,
		AVCP_TABLET_SMALL_SCREEN = 2,
		AVCP_VERY_SMALL_SCREEN = 3,
		AVCP_HIGH_SCALE_FACTOR = 4
	}

	[ComImport]
$(if (($PSEdition -eq "Core") -Or ($OSBuild -lt 17134)) {@"
// Windows 10 1607 and Server 2016 or Powershell Core:
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
"@ } else {@"
// Windows 10 1803, up and Windows Powershell:
	[InterfaceType(ComInterfaceType.InterfaceIsIInspectable)]
"@ })
$(if ($OSBuild -lt 17134) {@"
// Windows 10 1607 and Server 2016:
	[Guid("9AC0B5C8-1484-4C5B-9533-4134A0F97CEA")]
"@ })
$(if (($OSBuild -ge 17134) -And ($OSBuild -lt 17661)) {@"
// Windows 10 1803:
	[Guid("871F602A-2B58-42B4-8C4B-6C43D642C06F")]
"@ })
$(if ($OSBuild -ge 17661) {@"
// Windows 10 1809 or up and Windows 11:
	[Guid("372E1D3B-38D3-42E4-A15B-8AB2B178F513")]
"@ })
	internal interface IApplicationView
	{
		int SetFocus();
		int SwitchTo();
		int TryInvokeBack(IntPtr /* IAsyncCallback* */ callback);
		int GetThumbnailWindow(out IntPtr hwnd);
		int GetMonitor(out IntPtr /* IImmersiveMonitor */ immersiveMonitor);
		int GetVisibility(out int visibility);
		int SetCloak(APPLICATION_VIEW_CLOAK_TYPE cloakType, int unknown);
		int GetPosition(ref Guid guid /* GUID for IApplicationViewPosition */, out IntPtr /* IApplicationViewPosition** */ position);
		int SetPosition(ref IntPtr /* IApplicationViewPosition* */ position);
		int InsertAfterWindow(IntPtr hwnd);
		int GetExtendedFramePosition(out Rect rect);
		int GetAppUserModelId([MarshalAs(UnmanagedType.LPWStr)] out string id);
		int SetAppUserModelId(string id);
		int IsEqualByAppUserModelId(string id, out int result);
		int GetViewState(out uint state);
		int SetViewState(uint state);
		int GetNeediness(out int neediness);
		int GetLastActivationTimestamp(out ulong timestamp);
		int SetLastActivationTimestamp(ulong timestamp);
		int GetVirtualDesktopId(out Guid guid);
		int SetVirtualDesktopId(ref Guid guid);
		int GetShowInSwitchers(out int flag);
		int SetShowInSwitchers(int flag);
		int GetScaleFactor(out int factor);
		int CanReceiveInput(out bool canReceiveInput);
		int GetCompatibilityPolicyType(out APPLICATION_VIEW_COMPATIBILITY_POLICY flags);
		int SetCompatibilityPolicyType(APPLICATION_VIEW_COMPATIBILITY_POLICY flags);
$(if ($OSBuild -lt 17134) {@"
		int GetPositionPriority(out IntPtr /* IShellPositionerPriority** */ priority);
		int SetPositionPriority(IntPtr /* IShellPositionerPriority* */ priority);
"@ })
		int GetSizeConstraints(IntPtr /* IImmersiveMonitor* */ monitor, out Size size1, out Size size2);
		int GetSizeConstraintsForDpi(uint uint1, out Size size1, out Size size2);
		int SetSizeConstraintsForDpi(ref uint uint1, ref Size size1, ref Size size2);
$(if ($OSBuild -lt 17134) {@"
		int QuerySizeConstraintsFromApp();
"@ })
		int OnMinSizePreferencesUpdated(IntPtr hwnd);
		int ApplyOperation(IntPtr /* IApplicationViewOperation* */ operation);
		int IsTray(out bool isTray);
		int IsInHighZOrderBand(out bool isInHighZOrderBand);
		int IsSplashScreenPresented(out bool isSplashScreenPresented);
		int Flash();
		int GetRootSwitchableOwner(out IApplicationView rootSwitchableOwner);
		int EnumerateOwnershipTree(out IObjectArray ownershipTree);
		int GetEnterpriseId([MarshalAs(UnmanagedType.LPWStr)] out string enterpriseId);
		int IsMirrored(out bool isMirrored);
$(if (($OSBuild -ge 17134) -And ($OSBuild -lt 17661)) {@"
		int Unknown1(out int unknown);
		int Unknown2(out int unknown);
		int Unknown3(out int unknown);
		int Unknown4(out int unknown);
"@ })
$(if ($OSBuild -ge 17661) {@"
		int Unknown1(out int unknown);
		int Unknown2(out int unknown);
		int Unknown3(out int unknown);
		int Unknown4(out int unknown);
		int Unknown5(out int unknown);
		int Unknown6(int unknown);
		int Unknown7();
		int Unknown8(out int unknown);
		int Unknown9(int unknown);
		int Unknown10(int unknownX, int unknownY);
		int Unknown11(int unknown);
		int Unknown12(out Size size1);
"@ })
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
$(if ($OSBuild -lt 17134) {@"
// Windows 10 1607 and Server 2016:
	[Guid("2C08ADF0-A386-4B35-9250-0FE183476FCC")]
"@ })
$(if (($OSBuild -ge 17134) -And ($OSBuild -lt 17661)) {@"
// Windows 10 1803:
	[Guid("2C08ADF0-A386-4B35-9250-0FE183476FCC")]
"@ })
$(if ($OSBuild -ge 17661) {@"
// Windows 10 1809 or up and Windows 11:
	[Guid("1841C6D7-4F9D-42C0-AF41-8747538F10E5")]
"@ })
	internal interface IApplicationViewCollection
	{
		int GetViews(out IObjectArray array);
		int GetViewsByZOrder(out IObjectArray array);
		int GetViewsByAppUserModelId(string id, out IObjectArray array);
		int GetViewForHwnd(IntPtr hwnd, out IApplicationView view);
		int GetViewForApplication(object application, out IApplicationView view);
		int GetViewForAppUserModelId(string id, out IApplicationView view);
		int GetViewInFocus(out IntPtr view);
$(if ($OSBuild -ge 17134) {@"
// Windows 10 1803 or up and Windows 11:
		int Unknown1(out IntPtr view);
"@ })
		void RefreshCollection();
		int RegisterForApplicationViewChanges(object listener, out int cookie);
$(if ($OSBuild -lt 17661) {@"
// Windows 10 1607 and Server 2016 and Windows 10 1803:
		int RegisterForApplicationViewPositionChanges(object listener, out int cookie);
"@ })
		int UnregisterForApplicationViewChanges(int cookie);
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
$(if ($OSBuild -ge 22621) {@"
// Windows 11 22H2 and up:
	[Guid("3F07F4BE-B107-441A-AF0F-39D82529072C")]
"@ })
$(if (($OSBuild -ge 22000) -And ($OSBuild -lt 22621)) {@"
// Windows 11 up to 21H2:
	[Guid("536D3495-B208-4CC9-AE26-DE8111275BF8")]
"@ })
$(if ($OSBuild -eq 20348) {@"
// Windows Server 2022:
	[Guid("62fdf88b-11ca-4afb-8bd8-2296dfae49e2")]
"@ })
$(if ($OSBuild -lt 20348) {@"
// Windows 10:
	[Guid("FF72FFDD-BE7E-43FC-9C03-AD81681E88E4")]
"@ })
	internal interface IVirtualDesktop
	{
		bool IsViewVisible(IApplicationView view);
		Guid GetId();
$(if (($OSBuild -ge 20348) -And ($OSBuild -lt 22621)) {@"
// Windows Server 2022 and Windows 11 up to 21H2
		IntPtr Unknown1();
"@ })
$(if ($OSBuild -ge 20348) {@"
// Windows Server 2022 and Windows 11
		HString GetName();
"@ })
$(if ($OSBuild -ge 22000) {@"
// Windows 11:
		HString GetWallpaperPath();
"@ })
$(if ($OSBuild -ge 22621) {@"
// Windows 11 22H2 and up:
		bool IsRemote();
"@ })
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
$(if ($OSBuild -ge 22621) {@"
// Windows 11 22H2 and up:
	[Guid("53F5CA0B-158F-4124-900C-057158060B27")]
	internal interface IVirtualDesktopManagerInternal
	{
		int GetCount();
		void MoveViewToDesktop(IApplicationView view, IVirtualDesktop desktop);
		bool CanViewMoveDesktops(IApplicationView view);
		IVirtualDesktop GetCurrentDesktop();
		void GetDesktops(out IObjectArray desktops);
		[PreserveSig]
		int GetAdjacentDesktop(IVirtualDesktop from, int direction, out IVirtualDesktop desktop);
		void SwitchDesktop(IVirtualDesktop desktop);
		IVirtualDesktop CreateDesktop();
		void MoveDesktop(IVirtualDesktop desktop, int nIndex);
		void RemoveDesktop(IVirtualDesktop desktop, IVirtualDesktop fallback);
		IVirtualDesktop FindDesktop(ref Guid desktopid);
		void GetDesktopSwitchIncludeExcludeViews(IVirtualDesktop desktop, out IObjectArray unknown1, out IObjectArray unknown2);
		void SetDesktopName(IVirtualDesktop desktop, HString name);
		void SetDesktopWallpaper(IVirtualDesktop desktop, HString path);
		void UpdateWallpaperPathForAllDesktops(HString path);
		void CopyDesktopState(IApplicationView pView0, IApplicationView pView1);
		void CreateRemoteDesktop(HString path, out IVirtualDesktop desktop);
		void SwitchRemoteDesktop(IVirtualDesktop desktop, IntPtr switchtype);
		void SwitchDesktopWithAnimation(IVirtualDesktop desktop);
		void GetLastActiveDesktop(out IVirtualDesktop desktop);
		void WaitForAnimationToComplete();
	}
"@ })
$(if (($OSBuild -ge 22000) -And ($OSBuild -lt 22621)) {@"
// Windows 11 up to 21H2:
	[Guid("B2F925B9-5A0F-4D2E-9F4D-2B1507593C10")]
	internal interface IVirtualDesktopManagerInternal
	{
		int GetCount(IntPtr hWndOrMon);
		void MoveViewToDesktop(IApplicationView view, IVirtualDesktop desktop);
		bool CanViewMoveDesktops(IApplicationView view);
		IVirtualDesktop GetCurrentDesktop(IntPtr hWndOrMon);
"@ })
$(if (($OSBuild -ge 22449) -And ($OSBuild -lt 22621)) {@"
// Windows 11 up to 21H2:
		IObjectArray GetAllCurrentDesktops();
		void GetDesktops(IntPtr hWndOrMon, out IObjectArray desktops);
		[PreserveSig]
		int GetAdjacentDesktop(IVirtualDesktop from, int direction, out IVirtualDesktop desktop);
		void SwitchDesktop(IntPtr hWndOrMon, IVirtualDesktop desktop);
		IVirtualDesktop CreateDesktop(IntPtr hWndOrMon);
		void MoveDesktop(IVirtualDesktop desktop, IntPtr hWndOrMon, int nIndex);
		void RemoveDesktop(IVirtualDesktop desktop, IVirtualDesktop fallback);
		IVirtualDesktop FindDesktop(ref Guid desktopid);
		void GetDesktopSwitchIncludeExcludeViews(IVirtualDesktop desktop, out IObjectArray unknown1, out IObjectArray unknown2);
		void SetDesktopName(IVirtualDesktop desktop, HString name);
		void SetDesktopWallpaper(IVirtualDesktop desktop, HString path);
		void UpdateWallpaperPathForAllDesktops(HString path);
		void CopyDesktopState(IApplicationView pView0, IApplicationView pView1);
		int GetDesktopIsPerMonitor();
		void SetDesktopIsPerMonitor(bool state);
	}
"@ })
$(if ($OSBuild -eq 20348) {@"
// Windows Server 2022:
	[Guid("094afe11-44f2-4ba0-976f-29a97e263ee0")]
	internal interface IVirtualDesktopManagerInternal
	{
		int GetCount(IntPtr hWndOrMon);
		void MoveViewToDesktop(IApplicationView view, IVirtualDesktop desktop);
		bool CanViewMoveDesktops(IApplicationView view);
		IVirtualDesktop GetCurrentDesktop(IntPtr hWndOrMon);
		void GetDesktops(IntPtr hWndOrMon, out IObjectArray desktops);
		[PreserveSig]
		int GetAdjacentDesktop(IVirtualDesktop from, int direction, out IVirtualDesktop desktop);
		void SwitchDesktop(IntPtr hWndOrMon, IVirtualDesktop desktop);
		IVirtualDesktop CreateDesktop(IntPtr hWndOrMon);
		void RemoveDesktop(IVirtualDesktop desktop, IVirtualDesktop fallback);
		IVirtualDesktop FindDesktop(ref Guid desktopid);
		void GetDesktopSwitchIncludeExcludeViews(IVirtualDesktop desktop, out IObjectArray unknown1, out IObjectArray unknown2);
		void SetDesktopName(IVirtualDesktop desktop, HString name);
		void CopyDesktopState(IApplicationView pView0, IApplicationView pView1);
		int GetDesktopIsPerMonitor();
	}
"@ })
$(if ($OSBuild -lt 20348) {@"
// Windows 10:
	[Guid("F31574D6-B682-4CDC-BD56-1827860ABEC6")]
	internal interface IVirtualDesktopManagerInternal
	{
		int GetCount();
		void MoveViewToDesktop(IApplicationView view, IVirtualDesktop desktop);
		bool CanViewMoveDesktops(IApplicationView view);
		IVirtualDesktop GetCurrentDesktop();
		void GetDesktops(out IObjectArray desktops);
		[PreserveSig]
		int GetAdjacentDesktop(IVirtualDesktop from, int direction, out IVirtualDesktop desktop);
		void SwitchDesktop(IVirtualDesktop desktop);
		IVirtualDesktop CreateDesktop();
		void RemoveDesktop(IVirtualDesktop desktop, IVirtualDesktop fallback);
		IVirtualDesktop FindDesktop(ref Guid desktopid);
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("0F3A72B0-4566-487E-9A33-4ED302F6D6CE")]
	internal interface IVirtualDesktopManagerInternal2
	{
		int GetCount();
		void MoveViewToDesktop(IApplicationView view, IVirtualDesktop desktop);
		bool CanViewMoveDesktops(IApplicationView view);
		IVirtualDesktop GetCurrentDesktop();
		void GetDesktops(out IObjectArray desktops);
		[PreserveSig]
		int GetAdjacentDesktop(IVirtualDesktop from, int direction, out IVirtualDesktop desktop);
		void SwitchDesktop(IVirtualDesktop desktop);
		IVirtualDesktop CreateDesktop();
		void RemoveDesktop(IVirtualDesktop desktop, IVirtualDesktop fallback);
		IVirtualDesktop FindDesktop(ref Guid desktopid);
		void Unknown1(IVirtualDesktop desktop, out IntPtr unknown1, out IntPtr unknown2);
		void SetName(IVirtualDesktop desktop, HString name);
	}
"@ })

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("A5CD92FF-29BE-454C-8D04-D82879FB3F1B")]
	internal interface IVirtualDesktopManager
	{
		bool IsWindowOnCurrentVirtualDesktop(IntPtr topLevelWindow);
		Guid GetWindowDesktopId(IntPtr topLevelWindow);
		void MoveWindowToDesktop(IntPtr topLevelWindow, ref Guid desktopId);
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("4CE81583-1E4C-4632-A621-07A53543148F")]
	internal interface IVirtualDesktopPinnedApps
	{
		bool IsAppIdPinned(string appId);
		void PinAppID(string appId);
		void UnpinAppID(string appId);
		bool IsViewPinned(IApplicationView applicationView);
		void PinView(IApplicationView applicationView);
		void UnpinView(IApplicationView applicationView);
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("92CA9DCD-5622-4BBA-A805-5E9F541BD8C9")]
	internal interface IObjectArray
	{
		void GetCount(out int count);
		void GetAt(int index, ref Guid iid, [MarshalAs(UnmanagedType.Interface)]out object obj);
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("6D5140C1-7436-11CE-8034-00AA006009FA")]
	internal interface IServiceProvider10
	{
		[return: MarshalAs(UnmanagedType.IUnknown)]
		object QueryService(ref Guid service, ref Guid riid);
	}
	#endregion

	#region COM wrapper
	internal static class DesktopManager
	{
		static DesktopManager()
		{
			var shell = (IServiceProvider10)Activator.CreateInstance(Type.GetTypeFromCLSID(Guids.CLSID_ImmersiveShell));
			VirtualDesktopManagerInternal = (IVirtualDesktopManagerInternal)shell.QueryService(Guids.CLSID_VirtualDesktopManagerInternal, typeof(IVirtualDesktopManagerInternal).GUID);
$(if ($OSBuild -lt 20348) {@"
// Windows 10:
			try {
				VirtualDesktopManagerInternal2 = (IVirtualDesktopManagerInternal2)shell.QueryService(Guids.CLSID_VirtualDesktopManagerInternal, typeof(IVirtualDesktopManagerInternal2).GUID);
			}
			catch {
				VirtualDesktopManagerInternal2 = null;
			}
"@ })
			VirtualDesktopManager = (IVirtualDesktopManager)Activator.CreateInstance(Type.GetTypeFromCLSID(Guids.CLSID_VirtualDesktopManager));
			ApplicationViewCollection = (IApplicationViewCollection)shell.QueryService(typeof(IApplicationViewCollection).GUID, typeof(IApplicationViewCollection).GUID);
			VirtualDesktopPinnedApps = (IVirtualDesktopPinnedApps)shell.QueryService(Guids.CLSID_VirtualDesktopPinnedApps, typeof(IVirtualDesktopPinnedApps).GUID);
		}

		internal static IVirtualDesktopManagerInternal VirtualDesktopManagerInternal;
$(if ($OSBuild -lt 20348) {@"
// Windows 10:
		internal static IVirtualDesktopManagerInternal2 VirtualDesktopManagerInternal2;
"@ })
		internal static IVirtualDesktopManager VirtualDesktopManager;
		internal static IApplicationViewCollection ApplicationViewCollection;
		internal static IVirtualDesktopPinnedApps VirtualDesktopPinnedApps;

		internal static IVirtualDesktop GetDesktop(int index)
		{	// get desktop with index
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			int count = VirtualDesktopManagerInternal.GetCount();
"@ } else {@"
			int count = VirtualDesktopManagerInternal.GetCount(IntPtr.Zero);
"@ })
			if (index < 0 || index >= count) throw new ArgumentOutOfRangeException("index");
			IObjectArray desktops;
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			VirtualDesktopManagerInternal.GetDesktops(out desktops);
"@ } else {@"
			VirtualDesktopManagerInternal.GetDesktops(IntPtr.Zero, out desktops);
"@ })
			object objdesktop;
			desktops.GetAt(index, typeof(IVirtualDesktop).GUID, out objdesktop);
			Marshal.ReleaseComObject(desktops);
			return (IVirtualDesktop)objdesktop;
		}

		internal static int GetDesktopIndex(IVirtualDesktop desktop)
		{ // get index of desktop
			int index = -1;
			Guid IdSearch = desktop.GetId();
			IObjectArray desktops;
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			VirtualDesktopManagerInternal.GetDesktops(out desktops);
"@ } else {@"
			VirtualDesktopManagerInternal.GetDesktops(IntPtr.Zero, out desktops);
"@ })
			object objdesktop;
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			for (int i = 0; i < VirtualDesktopManagerInternal.GetCount(); i++)
"@ } else {@"
			for (int i = 0; i < VirtualDesktopManagerInternal.GetCount(IntPtr.Zero); i++)
"@ })
			{
				desktops.GetAt(i, typeof(IVirtualDesktop).GUID, out objdesktop);
				if (IdSearch.CompareTo(((IVirtualDesktop)objdesktop).GetId()) == 0)
				{ index = i;
					break;
				}
			}
			Marshal.ReleaseComObject(desktops);
			return index;
		}

		internal static IApplicationView GetApplicationView(this IntPtr hWnd)
		{ // get application view to window handle
			IApplicationView view;
			ApplicationViewCollection.GetViewForHwnd(hWnd, out view);
			return view;
		}

		internal static string GetAppId(IntPtr hWnd)
		{ // get Application ID to window handle
			string appId;
			hWnd.GetApplicationView().GetAppUserModelId(out appId);
			return appId;
		}
	}
	#endregion

	#region public interface
	public class WindowInformation
	{ // stores window informations
		public string Title { get; set; }
		public int Handle { get; set; }
	}

	public class Desktop
	{
		// open registry key
		[DllImport("advapi32.dll", CharSet=CharSet.Auto)]
		private static extern int RegOpenKeyEx(UIntPtr hKey, string subKey, int ulOptions, int samDesired, out UIntPtr hkResult);

		// read registry value
		[DllImport("advapi32.dll", SetLastError=true)]
		private static extern uint RegQueryValueEx(UIntPtr hKey, string lpValueName, int lpReserved, ref int lpType, IntPtr lpData, ref int lpcbData);

		// close registry key
		[DllImport("advapi32.dll", SetLastError=true)]
		private static extern int RegCloseKey(UIntPtr hKey);

		// get window handle of current console window (even if powershell started in cmd)
		[DllImport("Kernel32.dll")]
		public static extern IntPtr GetConsoleWindow();

		// get process id of window handle
		[DllImport("user32.dll")]
		private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);

		// get thread id of current process
		[DllImport("kernel32.dll")]
		static extern uint GetCurrentThreadId();

		// attach input to thread
		[DllImport("user32.dll")]
		static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

		// get handle of active window
		[DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();

		// try to set foreground window
		[DllImport("user32.dll")]
		[return: MarshalAs(UnmanagedType.Bool)]static extern bool SetForegroundWindow(IntPtr hWnd);

		// send message to window
		[DllImport("user32.dll")]
		static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
		private const int SW_MINIMIZE = 6;

		private static UIntPtr HKEY_CURRENT_USER = new UIntPtr(0x80000001u);
		private const int KEY_READ = 0x20019;

		private static string GetRegistryString(string registryPath, string valName)
		{ // reads string value out of user registry
			UIntPtr hKey = UIntPtr.Zero;
			IntPtr pResult = IntPtr.Zero;
			string Result = null;

			try
			{
				if (RegOpenKeyEx(HKEY_CURRENT_USER, registryPath, 0, KEY_READ, out hKey) == 0)
				{
					int size = 0;
					int type = 1; // REG_SZ

					uint retVal = RegQueryValueEx(hKey, valName, 0, ref type, IntPtr.Zero, ref size);
					if (size != 0)
					{
						pResult = Marshal.AllocHGlobal(size);

						retVal = RegQueryValueEx(hKey, valName, 0, ref type, pResult, ref size);
						if (retVal == 0) { Result = Marshal.PtrToStringAnsi(pResult); }
					}
				}
			}
			catch { }
			finally
			{
				if (hKey != UIntPtr.Zero) { RegCloseKey(hKey); }
				if (pResult != IntPtr.Zero) { Marshal.FreeHGlobal(pResult); }
			}

			return Result;
		}

		private static readonly Guid AppOnAllDesktops = new Guid("BB64D5B7-4DE3-4AB2-A87C-DB7601AEA7DC");
		private static readonly Guid WindowOnAllDesktops = new Guid("C2DDEA68-66F2-4CF9-8264-1BFD00FBBBAC");

		private IVirtualDesktop ivd;
		private Desktop(IVirtualDesktop desktop) { this.ivd = desktop; }

		public override int GetHashCode()
		{ // get hash
			return ivd.GetHashCode();
		}

		public override bool Equals(object obj)
		{ // compare with object
			var desk = obj as Desktop;
			return desk != null && object.ReferenceEquals(this.ivd, desk.ivd);
		}

		public static int Count
		{ // return the number of desktops
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			get { return DesktopManager.VirtualDesktopManagerInternal.GetCount(); }
"@ } else {@"
			get { return DesktopManager.VirtualDesktopManagerInternal.GetCount(IntPtr.Zero); }
"@ })
		}

		public static Desktop Current
		{ // returns current desktop
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			get { return new Desktop(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop()); }
"@ } else {@"
			get { return new Desktop(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop(IntPtr.Zero)); }
"@ })
		}

		public static Desktop FromIndex(int index)
		{ // return desktop object from index (-> index = 0..Count-1)
			return new Desktop(DesktopManager.GetDesktop(index));
		}

		public static Desktop FromWindow(IntPtr hWnd)
		{ // return desktop object to desktop on which window <hWnd> is displayed
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			Guid id = DesktopManager.VirtualDesktopManager.GetWindowDesktopId(hWnd);
			if ((id.CompareTo(AppOnAllDesktops) == 0) || (id.CompareTo(WindowOnAllDesktops) == 0))
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
				return new Desktop(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());
"@ } else {@"
				return new Desktop(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop(IntPtr.Zero));
"@ })
			else
				return new Desktop(DesktopManager.VirtualDesktopManagerInternal.FindDesktop(ref id));
		}

		public static int FromDesktop(Desktop desktop)
		{ // return index of desktop object or -1 if not found
			return DesktopManager.GetDesktopIndex(desktop.ivd);
		}

		public static string DesktopNameFromDesktop(Desktop desktop)
		{ // return name of desktop or "Desktop n" if it has no name
			Guid guid = desktop.ivd.GetId();

			// read desktop name in registry
			string desktopName = null;
			try {
				desktopName = GetRegistryString("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VirtualDesktops\\Desktops\\{" + guid.ToString() + "}", "Name");
			}
			catch { }

			// no name found, generate generic name
			if (string.IsNullOrEmpty(desktopName))
			{ // create name "Desktop n" (n = number starting with 1)
				desktopName = "Desktop " + (DesktopManager.GetDesktopIndex(desktop.ivd) + 1).ToString();
			}
			return desktopName;
		}

		public static string DesktopNameFromIndex(int index)
		{ // return name of desktop from index (-> index = 0..Count-1) or "Desktop n" if it has no name
			Guid guid = DesktopManager.GetDesktop(index).GetId();

			// read desktop name in registry
			string desktopName = null;
			try {
				desktopName = GetRegistryString("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VirtualDesktops\\Desktops\\{" + guid.ToString() + "}", "Name");
			}
			catch { }

			// no name found, generate generic name
			if (string.IsNullOrEmpty(desktopName))
			{ // create name "Desktop n" (n = number starting with 1)
				desktopName = "Desktop " + (index + 1).ToString();
			}
			return desktopName;
		}

		public static bool HasDesktopNameFromIndex(int index)
		{ // return true is desktop is named or false if it has no name
			Guid guid = DesktopManager.GetDesktop(index).GetId();

			// read desktop name in registry
			string desktopName = null;
			try {
				desktopName = GetRegistryString("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VirtualDesktops\\Desktops\\{" + guid.ToString() + "}", "Name");
			}
			catch { }

			// name found?
			if (string.IsNullOrEmpty(desktopName))
				return false;
			else
				return true;
		}

$(if ($OSBuild -ge 22000) {@"
		public static string DesktopWallpaperFromIndex(int index)
		{ // return name of desktop wallpaper from index (-> index = 0..Count-1)

			// get desktop name
			string desktopwppath = "";
			try {
				desktopwppath = DesktopManager.GetDesktop(index).GetWallpaperPath();
			}
			catch { }

			return desktopwppath;
		}
"@ })

		public static int SearchDesktop(string partialName)
		{ // get index of desktop with partial name, return -1 if no desktop found
			int index = -1;

$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			for (int i = 0; i < DesktopManager.VirtualDesktopManagerInternal.GetCount(); i++)
"@ } else {@"
			for (int i = 0; i < DesktopManager.VirtualDesktopManagerInternal.GetCount(IntPtr.Zero); i++)
"@ })
			{ // loop through all virtual desktops and compare partial name to desktop name
				if (DesktopNameFromIndex(i).ToUpper().IndexOf(partialName.ToUpper()) >= 0)
				{ index = i;
					break;
				}
			}

			return index;
		}

		public static Desktop Create()
		{ // create a new desktop
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			return new Desktop(DesktopManager.VirtualDesktopManagerInternal.CreateDesktop());
"@ } else {@"
			return new Desktop(DesktopManager.VirtualDesktopManagerInternal.CreateDesktop(IntPtr.Zero));
"@ })
		}

		public void Remove(Desktop fallback = null)
		{ // destroy desktop and switch to <fallback>
			IVirtualDesktop fallbackdesktop;
			if (fallback == null)
			{ // if no fallback is given use desktop to the left except for desktop 0.
				Desktop dtToCheck = new Desktop(DesktopManager.GetDesktop(0));
				if (this.Equals(dtToCheck))
				{ // desktop 0: set fallback to second desktop (= "right" desktop)
					DesktopManager.VirtualDesktopManagerInternal.GetAdjacentDesktop(ivd, 4, out fallbackdesktop); // 4 = RightDirection
				}
				else
				{ // set fallback to "left" desktop
					DesktopManager.VirtualDesktopManagerInternal.GetAdjacentDesktop(ivd, 3, out fallbackdesktop); // 3 = LeftDirection
				}
			}
			else
				// set fallback desktop
				fallbackdesktop = fallback.ivd;

			DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(ivd, fallbackdesktop);
		}

$(if ($OSBuild -lt 20348) {@"
// Windows 10:
		public static void RemoveAll()
		{ // remove all desktops but visible
			int desktopcount = DesktopManager.VirtualDesktopManagerInternal.GetCount();
			int desktopcurrent = DesktopManager.GetDesktopIndex(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());

			if (desktopcurrent < desktopcount-1)
			{ // remove all desktops "right" from current
				for (int i = desktopcount-1; i > desktopcurrent; i--)
					DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(DesktopManager.GetDesktop(i), DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());
			}
			if (desktopcurrent > 0)
			{ // remove all desktops "left" from current
				for (int i = 0; i < desktopcurrent; i++)
					DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(DesktopManager.GetDesktop(0), DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());
			}
		}
"@ })

$(if ($OSBuild -eq 20348) {@"
// Windows Server 2022:
		public static void RemoveAll()
		{ // remove all desktops but visible
			int desktopcount = DesktopManager.VirtualDesktopManagerInternal.GetCount(IntPtr.Zero);
			int desktopcurrent = DesktopManager.GetDesktopIndex(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop(IntPtr.Zero));

			if (desktopcurrent < desktopcount-1)
			{ // remove all desktops "right" from current
				for (int i = desktopcount-1; i > desktopcurrent; i--)
					DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(DesktopManager.GetDesktop(i), DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop(IntPtr.Zero));
			}
			if (desktopcurrent > 0)
			{ // remove all desktops "left" from current
				for (int i = 0; i < desktopcurrent; i++)
					DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(DesktopManager.GetDesktop(0), DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop(IntPtr.Zero));
			}
		}
"@ })

$(if (($OSBuild -ge 22000) -And ($OSBuild -lt 22621)) {@"
		public static void RemoveAll()
		{ // remove all desktops but visible
			DesktopManager.VirtualDesktopManagerInternal.SetDesktopIsPerMonitor(true);
		}

		public void Move(int index)
		{ // move current desktop to desktop in index (-> index = 0..Count-1)
			DesktopManager.VirtualDesktopManagerInternal.MoveDesktop(ivd, IntPtr.Zero, index);
		}
"@ })

$(if ($OSBuild -ge 22621) {@"
		public static void RemoveAll()
		{ // remove all desktops but visible
			int desktopcount = DesktopManager.VirtualDesktopManagerInternal.GetCount();
			int desktopcurrent = DesktopManager.GetDesktopIndex(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());

			if (desktopcurrent < desktopcount-1)
			{ // remove all desktops "right" from current
				for (int i = desktopcount-1; i > desktopcurrent; i--)
					DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(DesktopManager.GetDesktop(i), DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());
			}
			if (desktopcurrent > 0)
			{ // remove all desktops "left" from current
				for (int i = 0; i < desktopcurrent; i++)
					DesktopManager.VirtualDesktopManagerInternal.RemoveDesktop(DesktopManager.GetDesktop(0), DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop());
			}
		}

		public void Move(int index)
		{ // move current desktop to desktop in index (-> index = 0..Count-1)
			DesktopManager.VirtualDesktopManagerInternal.MoveDesktop(ivd, index);
		}
"@ })

$(if ($OSBuild -lt 20348) {@"
		public void SetName(string Name)
		{ // set name for desktop, empty string removes name
			if (DesktopManager.VirtualDesktopManagerInternal2 != null)
			{ // only if interface to set name is present
				HString hstring = HString.FromString(Name);
				DesktopManager.VirtualDesktopManagerInternal2.SetName(this.ivd, hstring);
				hstring.Delete();
			}
		}
"@ })
$(if ($OSBuild -ge 20348) {@"
		public void SetName(string Name)
		{ // set name for desktop, empty string removes name
			HString hstring = HString.FromString(Name);
			DesktopManager.VirtualDesktopManagerInternal.SetDesktopName(this.ivd, hstring);
			hstring.Delete();
		}
"@ })

$(if ($OSBuild -ge 22000) {@"
		public void SetWallpaperPath(string Path)
		{ // set path for wallpaper, empty string removes path
			if (string.IsNullOrEmpty(Path)) throw new ArgumentNullException();
			HString hstring = HString.FromString(Path);
			DesktopManager.VirtualDesktopManagerInternal.SetDesktopWallpaper(this.ivd, hstring);
			hstring.Delete();
		}

		public static void SetAllWallpaperPaths(string Path)
		{ // set wallpaper path for all desktops
			if (string.IsNullOrEmpty(Path)) throw new ArgumentNullException();
			HString hstring = HString.FromString(Path);
			DesktopManager.VirtualDesktopManagerInternal.UpdateWallpaperPathForAllDesktops(hstring);
			hstring.Delete();
		}
"@ })

		public bool IsVisible
		{ // return true if this desktop is the current displayed one
$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			get { return object.ReferenceEquals(ivd, DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop()); }
"@ } else {@"
			get { return object.ReferenceEquals(ivd, DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop(IntPtr.Zero)); }
"@ })
		}

		public void MakeVisible()
		{ // make this desktop visible
			WindowInformation wi = FindWindow("Program Manager");

			// activate desktop to prevent flashing icons in taskbar
			int dummy;
			uint DesktopThreadId = GetWindowThreadProcessId(new IntPtr(wi.Handle), out dummy);
			uint ForegroundThreadId = GetWindowThreadProcessId(GetForegroundWindow(), out dummy);
			uint CurrentThreadId = GetCurrentThreadId();

			if ((DesktopThreadId != 0) && (ForegroundThreadId != 0) && (ForegroundThreadId != CurrentThreadId))
			{
				AttachThreadInput(DesktopThreadId, CurrentThreadId, true);
				AttachThreadInput(ForegroundThreadId, CurrentThreadId, true);
				SetForegroundWindow(new IntPtr(wi.Handle));
				AttachThreadInput(ForegroundThreadId, CurrentThreadId, false);
				AttachThreadInput(DesktopThreadId, CurrentThreadId, false);
			}

$(if (($OSBuild -lt 20348) -Or ($OSBuild -ge 22621)) {@"
			DesktopManager.VirtualDesktopManagerInternal.SwitchDesktop(ivd);
"@ } else {@"
			DesktopManager.VirtualDesktopManagerInternal.SwitchDesktop(IntPtr.Zero, ivd);
"@ })

			// direct desktop to give away focus
			ShowWindow(new IntPtr(wi.Handle), SW_MINIMIZE);
		}

		public Desktop Left
		{ // return desktop at the left of this one, null if none
			get
			{
				IVirtualDesktop desktop;
				int hr = DesktopManager.VirtualDesktopManagerInternal.GetAdjacentDesktop(ivd, 3, out desktop); // 3 = LeftDirection
				if (hr == 0)
					return new Desktop(desktop);
				else
					return null;
			}
		}

		public Desktop Right
		{ // return desktop at the right of this one, null if none
			get
			{
				IVirtualDesktop desktop;
				int hr = DesktopManager.VirtualDesktopManagerInternal.GetAdjacentDesktop(ivd, 4, out desktop); // 4 = RightDirection
				if (hr == 0)
					return new Desktop(desktop);
				else
					return null;
			}
		}

		public void MoveWindow(IntPtr hWnd)
		{ // move window to this desktop
			int processId;
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			GetWindowThreadProcessId(hWnd, out processId);

			if (hWnd == GetConsoleWindow())
			{ // own window
				try // the easy way (powershell's own console)
				{
					DesktopManager.VirtualDesktopManager.MoveWindowToDesktop(hWnd, ivd.GetId());
				}
				catch // powershell in cmd console
				{
					IApplicationView view;
					DesktopManager.ApplicationViewCollection.GetViewForHwnd(hWnd, out view);
					DesktopManager.VirtualDesktopManagerInternal.MoveViewToDesktop(view, ivd);
				}
			}
			else
			{ // window of other process
				IApplicationView view;
				DesktopManager.ApplicationViewCollection.GetViewForHwnd(hWnd, out view);
				try {
					DesktopManager.VirtualDesktopManagerInternal.MoveViewToDesktop(view, ivd);
				}
				catch
				{ // could not move active window, try main window (or whatever windows thinks is the main window)
					DesktopManager.ApplicationViewCollection.GetViewForHwnd(System.Diagnostics.Process.GetProcessById(processId).MainWindowHandle, out view);
					DesktopManager.VirtualDesktopManagerInternal.MoveViewToDesktop(view, ivd);
				}
			}
		}

		public void MoveActiveWindow()
		{ // move active window to this desktop
			MoveWindow(GetForegroundWindow());
		}

		public bool HasWindow(IntPtr hWnd)
		{ // return true if window is on this desktop
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			Guid id = DesktopManager.VirtualDesktopManager.GetWindowDesktopId(hWnd);
			if ((id.CompareTo(AppOnAllDesktops) == 0) || (id.CompareTo(WindowOnAllDesktops) == 0))
				return true;
			else
				return ivd.GetId() == id;
		}

		public static bool IsWindowPinned(IntPtr hWnd)
		{ // return true if window is pinned to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			return DesktopManager.VirtualDesktopPinnedApps.IsViewPinned(hWnd.GetApplicationView());
		}

		public static void PinWindow(IntPtr hWnd)
		{ // pin window to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			var view = hWnd.GetApplicationView();
			if (!DesktopManager.VirtualDesktopPinnedApps.IsViewPinned(view))
			{ // pin only if not already pinned
				DesktopManager.VirtualDesktopPinnedApps.PinView(view);
			}
		}

		public static void UnpinWindow(IntPtr hWnd)
		{ // unpin window from all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			var view = hWnd.GetApplicationView();
			if (DesktopManager.VirtualDesktopPinnedApps.IsViewPinned(view))
			{ // unpin only if not already unpinned
				DesktopManager.VirtualDesktopPinnedApps.UnpinView(view);
			}
		}

		public static bool IsApplicationPinned(IntPtr hWnd)
		{ // return true if application for window is pinned to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			return DesktopManager.VirtualDesktopPinnedApps.IsAppIdPinned(DesktopManager.GetAppId(hWnd));
		}

		public static void PinApplication(IntPtr hWnd)
		{ // pin application for window to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			string appId = DesktopManager.GetAppId(hWnd);
			if (!DesktopManager.VirtualDesktopPinnedApps.IsAppIdPinned(appId))
			{ // pin only if not already pinned
				DesktopManager.VirtualDesktopPinnedApps.PinAppID(appId);
			}
		}

		public static void UnpinApplication(IntPtr hWnd)
		{ // unpin application for window from all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			var view = hWnd.GetApplicationView();
			string appId = DesktopManager.GetAppId(hWnd);
			if (DesktopManager.VirtualDesktopPinnedApps.IsAppIdPinned(appId))
			{ // unpin only if pinned
				DesktopManager.VirtualDesktopPinnedApps.UnpinAppID(appId);
			}
		}

		// prepare callback function for window enumeration
		private delegate bool CallBackPtr(int hwnd, int lParam);
		private static CallBackPtr callBackPtr = Callback;
		// list of window informations
		private static List<WindowInformation> WindowInformationList = new List<WindowInformation>();

		// enumerate windows
		[DllImport("User32.dll", SetLastError = true)]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool EnumWindows(CallBackPtr lpEnumFunc, IntPtr lParam);

		// get window title length
		[DllImport("User32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int GetWindowTextLength(IntPtr hWnd);

		// get window title
		[DllImport("User32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

		// callback function for window enumeration
		private static bool Callback(int hWnd, int lparam)
		{
			int length = GetWindowTextLength((IntPtr)hWnd);
			if (length > 0)
			{
				StringBuilder sb = new StringBuilder(length + 1);
				if (GetWindowText((IntPtr)hWnd, sb, sb.Capacity) > 0)
				{ WindowInformationList.Add(new WindowInformation {Handle = hWnd, Title = sb.ToString()}); }
			}
			return true;
		}

		// get list of all windows with title
		public static List<WindowInformation> GetWindows()
		{
			WindowInformationList = new List<WindowInformation>();
			EnumWindows(callBackPtr, IntPtr.Zero);
			return WindowInformationList;
		}

		// find first window with string in title
		public static WindowInformation FindWindow(string WindowTitle)
		{
			WindowInformationList = new List<WindowInformation>();
			EnumWindows(callBackPtr, IntPtr.Zero);
			WindowInformation result = WindowInformationList.Find(x => x.Title.IndexOf(WindowTitle, StringComparison.OrdinalIgnoreCase) >= 0);
			return result;
		}
	}
	#endregion
}
"@

function Get-DesktopCount
{
<#
.SYNOPSIS
Get count of virtual desktops
.DESCRIPTION
Get count of virtual desktops
.INPUTS
None
.OUTPUTS
Int32
.EXAMPLE
Get-DesktopCount

Get count of virtual desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param()

	Write-Verbose "Count of virtual desktops: $([VirtualDesktop.Desktop]::Count)"
	return [VirtualDesktop.Desktop]::Count
}


if ($OSBuild -ge 22000)
{
	function Get-DesktopList
	{
	<#
	.SYNOPSIS
	Get list of virtual desktops
	.DESCRIPTION
	Get list of virtual desktops
	.INPUTS
	None
	.OUTPUTS
	Object
	.EXAMPLE
	Get-DesktopList

	Get list of virtual desktops
	.LINK
	https://github.com/MScholtes/PSVirtualDesktop
	.LINK
	https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
	.LINK
	https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
	.NOTES
	Author: Markus Scholtes
	Created: 2020/06/27
	Updated: 2021/10/17
	#>
		$DesktopList = @()
		for ($I = 0; $I -lt [VirtualDesktop.Desktop]::Count; $I++)
		{
			$DesktopList += [PSCustomObject]@{
				Number = $I
				Name = [VirtualDesktop.Desktop]::DesktopNameFromIndex($I)
				Wallpaper = [VirtualDesktop.Desktop]::DesktopWallpaperFromIndex($I)
				Visible = if ([VirtualDesktop.Desktop]::FromDesktop([VirtualDesktop.Desktop]::Current) -eq $I) { $TRUE } else { $FALSE }
			}
		}
		return $DesktopList
	}
}
else
{
	function Get-DesktopList
	{
	<#
	.SYNOPSIS
	Get list of virtual desktops
	.DESCRIPTION
	Get list of virtual desktops
	.INPUTS
	None
	.OUTPUTS
	Object
	.EXAMPLE
	Get-DesktopList

	Get list of virtual desktops
	.LINK
	https://github.com/MScholtes/PSVirtualDesktop
	.LINK
	https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
	.LINK
	https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
	.NOTES
	Author: Markus Scholtes
	Created: 2020/06/27
	#>
		$DesktopList = @()
		for ($I = 0; $I -lt [VirtualDesktop.Desktop]::Count; $I++)
		{
			$DesktopList += [PSCustomObject]@{
				Number = $I
				Name = [VirtualDesktop.Desktop]::DesktopNameFromIndex($I)
				Visible = if ([VirtualDesktop.Desktop]::FromDesktop([VirtualDesktop.Desktop]::Current) -eq $I) { $TRUE } else { $FALSE }
			}
		}

		return $DesktopList
	}
}

function New-Desktop
{
<#
.SYNOPSIS
Create virtual desktop
.DESCRIPTION
Create virtual desktop
.INPUTS
None
.OUTPUTS
Desktop object
.EXAMPLE
New-Desktop | Switch-Desktop

Create virtual desktop and switch to it
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param()

	$Desktop = [VirtualDesktop.Desktop]::Create()
	Write-Verbose "Created desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop))"

	return $Desktop
}


function Switch-Desktop
{
<#
.SYNOPSIS
Switch to virtual desktop
.DESCRIPTION
Switch to virtual desktop
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
None
.EXAMPLE
Switch-Desktop 0

Switch to first virtual desktop
.EXAMPLE
Switch-Desktop $Desktop

Switch to virtual desktop $Desktop
.EXAMPLE
"Desktop 1" | Switch-Desktop

Switch to second virtual desktop
.EXAMPLE
New-Desktop | Switch-Desktop

Create virtual desktop and switch to it
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		$Desktop.MakeVisible()
		Write-Verbose "Switched to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				$TempDesktop.MakeVisible()
				Write-Verbose "Switched to desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					([VirtualDesktop.Desktop]::FromIndex($TempIndex)).MakeVisible()
					Write-Verbose "Switched to desktop number $([VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::FromIndex($TempIndex)))) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}
	}
}


function Remove-Desktop
{
<#
.SYNOPSIS
Remove virtual desktop
.DESCRIPTION
Remove virtual desktop.
Windows on the desktop to be removed are moved to the virtual desktop to the left except for desktop 0 where the
second desktop is used instead. If the current desktop is removed, this fallback desktop is activated too.
If no desktop is supplied, the last desktop is removed.
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
None
.EXAMPLE
Remove-Desktop 0

Remove first virtual desktop
.EXAMPLE
Remove-Desktop $Desktop

Remove virtual desktop $Desktop
.EXAMPLE
"Desktop 1" | Remove-Desktop

Remove second virtual desktop
.EXAMPLE
New-Desktop | Remove-Desktop

Create virtual desktop and remove it immediately
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::FromIndex(([VirtualDesktop.Desktop]::Count) -1)
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Removing desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		$Desktop.Remove()
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				Write-Verbose "Removing desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				$TempDesktop.Remove()
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					Write-Verbose "Removing desktop number $([VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::FromIndex($TempIndex)))) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
					([VirtualDesktop.Desktop]::FromIndex($TempIndex)).Remove()
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}
	}
}


function Remove-AllDesktops
{
<#
.SYNOPSIS
Remove all virtual desktops but visible
.DESCRIPTION
Remove all virtual desktops but visible
.INPUTS
None
.OUTPUTS
None
.EXAMPLE
Remove-AllDesktops

Remove all virtual desktops but visible
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.NOTES
Author: Markus Scholtes
Created: 2021/10/17
#>
	[VirtualDesktop.Desktop]::RemoveAll()
}


function Get-CurrentDesktop
{
<#
.SYNOPSIS
Get current virtual desktop
.DESCRIPTION
Get current virtual desktop as Desktop object
.INPUTS
None
.OUTPUTS
Desktop object
.EXAMPLE
Get-CurrentDesktop | Remove-Desktop

Remove current virtual desktop
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param()

	$Desktop = [VirtualDesktop.Desktop]::Current
	Write-Verbose "Current desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
	return $Desktop
}


function Get-Desktop
{
<#
.SYNOPSIS
Get virtual desktop with index number (0 to count-1) or string (part of desktop name)
.DESCRIPTION
Get virtual desktop with index number (0 to count-1) or string (part of desktop name)
Returns $NULL if index number is out of range.
Returns current desktop is index is omitted.
.PARAMETER Index
Number of desktop (starting with 0 to count-1) or string (part of desktop name)
.INPUTS
Int32 or STRING
.OUTPUTS
Desktop object
.EXAMPLE
Get-Desktop 1 | Switch-Desktop

Get object of second virtual desktop and switch to it
.EXAMPLE
"Desktop 1" | Get-Desktop | Switch-Desktop

Get object of second virtual desktop and switch to it
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[OutputType([VirtualDesktop.Desktop])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Index)

	if ($NULL -eq $Index)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
		Write-Verbose "Current desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		return $Desktop
	}

	if ($Index -is [ValueType])
	{
		$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Index)
		if ($NULL -ne $TempDesktop) { Write-Verbose "Desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')" }
		return $TempDesktop
	}
	else
	{
		if ($Index -is [STRING])
		{
			$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Index)
			if ($TempIndex -ge 0)
			{
				$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($TempIndex)
				Write-Verbose "Desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				return $TempDesktop
			}
			else
			{
				Write-Error "No desktop with name part '$Index' found"
				return $NULL
			}
		}
		else
		{
			Write-Error "Parameter -Index has to be an integer or string"
			return $NULL
		}
	}
}


function Get-DesktopIndex
{
<#
.SYNOPSIS
Get index number (0 to count-1) of virtual desktop
.DESCRIPTION
Get index number (0 to count-1) of virtual desktop
Returns -1 if desktop cannot be found.
Returns index of current desktop is parameter desktop is omitted.
.PARAMETER Desktop
Desktop object or string (part of desktop name)
.INPUTS
Desktop object or string (part of desktop name)
.OUTPUTS
Int32
.EXAMPLE
New-Desktop | Get-DesktopIndex

Get index number of new virtual desktop
.EXAMPLE
Get-DesktopIndex "desktop 1"

Get index number of desktop with name containing "desktop 1"
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2021/02/28
#>
	[OutputType([INT32])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		return [VirtualDesktop.Desktop]::FromDesktop($Desktop)
	}
	else
	{
		if ($Desktop -is [STRING])
		{
			$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
			if ($TempIndex -ge 0)
			{
				Write-Verbose "Desktop number $TempIndex ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
				return $TempIndex
			}
			else
			{
				Write-Error "No desktop with name part '$Desktop' found"
				return -1
			}
		}
		else
		{
			Write-Error "Parameter -Desktop has to be a desktop object or string"
			return -1
		}
	}
}


function Get-DesktopName
{
<#
.SYNOPSIS
Get name of virtual desktop
.DESCRIPTION
Get name of virtual desktop
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
String (name of desktop)
.EXAMPLE
Get-DesktopName 0

Get name of first desktop
.EXAMPLE
Get-DesktopName $Desktop

Get name of virtual desktop $Desktop
.EXAMPLE
"desktop" | Get-DesktopName

Get name of first virtual desktop whose name contains "desktop"
.EXAMPLE
New-Desktop | Get-DesktopName

Create virtual desktop and show its name
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2020/06/27
Updated: 2021/02/28
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Get name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		return ([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				Write-Verbose "Get name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				return ([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					Write-Verbose "Get name of desktop number $([VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::FromIndex($TempIndex)))) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
					return ([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}
	}
}


function Set-DesktopName
{
<#
.SYNOPSIS
Set name of virtual desktop
.DESCRIPTION
Set name of virtual desktop.
If parameter Desktop is not set, the name of the current desktop is used.
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.PARAMETER Name
Name of desktop. If omitted or empty or $NULL, a name will be removed from the desktop.
.PARAMETER PassThru
Return virtual desktop
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
None or [VirtualDesktop.Desktop]
.EXAMPLE
Set-DesktopName 0 "The first desktop"

Set name of first desktop
.EXAMPLE
Set-DesktopName $Desktop

Remove name of virtual desktop $Desktop
.EXAMPLE
"desktop" | Set-DesktopName -Name "First found"

Set name of first virtual desktop whose name contains "desktop"
.EXAMPLE
Set-DesktopName -Name "This is the current desktop"

Set name of the current virtual desktop
.EXAMPLE
New-Desktop | Set-DesktopName -Name "The new one" -PassThru | Get-DesktopName

Create virtual desktop, set its name and return the new name
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2020/06/27
Updated: 2021/10/18
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop, [Parameter(ValueFromPipeline = $FALSE)] $Name, [SWITCH]$PassThru)

	if ($NULL -eq $Name) { $Name = "" }
	if ($NULL -eq $Desktop) { $Desktop = [VirtualDesktop.Desktop]::Current }

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		if ($Name -ne "")
		{ Write-Verbose "Set name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))') to '$Name'" }
		else
		{ Write-Verbose "Remove name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')" }
		$Desktop.SetName($Name)
		$ActiveDesktop = $Desktop
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$ActiveDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($ActiveDesktop)
			{
				if ($Name -ne "")
				{ Write-Verbose "Set name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($ActiveDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($ActiveDesktop))') to '$Name'" }
				else
				{ Write-Verbose "Remove name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($ActiveDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($ActiveDesktop))')" }
				$ActiveDesktop.SetName($Name)
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					$ActiveDesktop = [VirtualDesktop.Desktop]::FromIndex($TempIndex)
					if ($Name -ne "")
					{ Write-Verbose "Set name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($ActiveDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($ActiveDesktop))') to '$Name'" }
					else
					{ Write-Verbose "Remove name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($ActiveDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($ActiveDesktop))')" }
					$ActiveDesktop.SetName($Name)
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}
	}
	if ($PassThru)
	{
		return $ActiveDesktop
	}
}


if ($OSBuild -ge 22000)
{
	function Set-DesktopWallpaper
	{
	<#
	.SYNOPSIS
	Set wallpaper of virtual desktop
	.DESCRIPTION
	Set wallpaper of virtual desktop
	.PARAMETER Desktop
	Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
	If parameter Desktop is not set, the name of the current desktop is used.
	.PARAMETER Path
	Path to wallpaper
	.PARAMETER PassThru
	Return virtual desktop
	.INPUTS
	Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
	.OUTPUTS
	None or [VirtualDesktop.Desktop]
	.EXAMPLE
	Set-DesktopWallpaper 0 "C:\Users\VD\Pictures\NicePic.jpg"

	Set wallpaper of first desktop
	.EXAMPLE
	Set-DesktopWallpaper -Path "C:\Users\VD\Pictures\CurrentDesktopPic.jpg"

	Set wallpaper of current desktop
	.EXAMPLE
	"First found" | Set-DesktopWallpaper -Path "C:\Windows\Web\Wallpaper\Windows\img0.jpg"

	Set wallpaper of first virtual desktop whose name contains "First found"
	.EXAMPLE
	New-Desktop | Set-DesktopWallpaper -Path "Background.jpg" -PassThru | Get-DesktopName

	Create virtual desktop, set its wallpaper and return the name
	.LINK
	https://github.com/MScholtes/PSVirtualDesktop
	.LINK
	https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
	.NOTES
	Author: Markus Scholtes
	Created: 2021/10/18
	#>
		[Cmdletbinding()]
		Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop, [Parameter(ValueFromPipeline = $FALSE)] $Path, [SWITCH]$PassThru)

		if ($NULL -eq $Desktop) { $Desktop = [VirtualDesktop.Desktop]::Current }

		if ($Desktop -is [VirtualDesktop.Desktop])
		{
			if ([STRING]::IsNullOrEmpty($Path))
			{ Write-Error "Wallpaper path is missing" }
			else
			{ Write-Verbose "Set wallpaper of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))') to '$Path'"
				$Desktop.SetWallpaperPath($Path)
			}
			$ActiveDesktop = $Desktop
		}
		else
		{
			if ($Desktop -is [ValueType])
			{
				$ActiveDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
				if ($ActiveDesktop)
				{
					if ([STRING]::IsNullOrEmpty($Path))
					{ Write-Error "Wallpaper path is missing" }
					else
					{ Write-Verbose "Set name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($ActiveDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($ActiveDesktop))') to '$Path'"
						$ActiveDesktop.SetWallpaperPath($Path)
					}
				}
			}
			else
			{
				if ($Desktop -is [STRING])
				{
					$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
					if ($TempIndex -ge 0)
					{
						$ActiveDesktop = [VirtualDesktop.Desktop]::FromIndex($TempIndex)
						if ([STRING]::IsNullOrEmpty($Path))
						{ Write-Error "Wallpaper path is missing" }
						else
						{ Write-Verbose "Set name of desktop number $([VirtualDesktop.Desktop]::FromDesktop($ActiveDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($ActiveDesktop))') to '$Path'"
							$ActiveDesktop.SetWallpaperPath($Path)
						}
					}
					else
					{
						Write-Error "No desktop with name part '$Desktop' found"
					}
				}
				else
				{
					Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
				}
			}
		}
		if ($PassThru)
		{
			return $ActiveDesktop
		}
	}


	function Set-AllDesktopWallpapers
	{
	<#
	.SYNOPSIS
	Set wallpaper of all virtual desktops
	.DESCRIPTION
	Set wallpaper of all virtual desktops
	.PARAMETER Path
	Path to wallpaper
	.INPUTS
	String
	.OUTPUTS
	None
	.EXAMPLE
	Set-AllDesktopWallpapers -Path "C:\Users\VD\Pictures\NicePic.jpg"

	Set wallpaper of all desktops
	.EXAMPLE
	"C:\Windows\Web\Wallpaper\Windows\img0.jpg" | Set-AllDesktopWallpapers

	Set wallpaper of all desktops
	.LINK
	https://github.com/MScholtes/PSVirtualDesktop
	.LINK
	https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
	.NOTES
	Author: Markus Scholtes
	Created: 2021/10/17
	#>
		[Cmdletbinding()]
		Param([Parameter(ValueFromPipeline = $TRUE)] $Path)

		if ([STRING]::IsNullOrEmpty($Path))
		{ Write-Error "Wallpaper path is missing" }
		else
		{ Write-Verbose "Set wallpaper of all desktops to '$Path'"
			[VirtualDesktop.Desktop]::SetAllWallpaperPaths($Path)
		}
	}
}


function Get-DesktopFromWindow
{
<#
.SYNOPSIS
Get virtual desktop of window
.DESCRIPTION
Get virtual desktop of window whose window handle is given.
Returns $NULL if window handle is unknown.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
Desktop object
.EXAMPLE
Get-DesktopFromWindow ((Get-Process "notepad")[0].MainWindowHandle) | Switch-Desktop

Switch to virtual desktop with notepad window
.EXAMPLE
Find-WindowHandle "notepad" | Get-DesktopFromWindow | Switch-Desktop

Switch to virtual desktop with notepad window
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[OutputType([VirtualDesktop.Desktop])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		$Desktop = [VirtualDesktop.Desktop]::FromWindow($Hwnd)
		if ($NULL -ne $Desktop) { Write-Verbose "Window is on desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')" }
		return $Desktop
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			$Desktop = [VirtualDesktop.Desktop]::FromWindow([IntPtr]$Hwnd)
			if ($NULL -ne $Desktop) { Write-Verbose "Window is on desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')" }
			return $Desktop
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
			return $NULL
		}
	}
}


function Test-CurrentDesktop
{
<#
.SYNOPSIS
Checks whether a desktop is the displayed virtual desktop
.DESCRIPTION
Checks whether a desktop is the displayed virtual desktop
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
Boolean
.EXAMPLE
Get-DesktopIndex 1 | Test-CurrentDesktop

Checks whether the desktop with count number 1 is the displayed virtual desktop
.EXAMPLE
Test-CurrentDesktop "desktop 2"

Checks whether the desktop with string "desktop 2" in name is the displayed virtual desktop
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Check visibility of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		return $Desktop.IsVisible
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				Write-Verbose "Check visibility of desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				return $TempDesktop.IsVisible
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					Write-Verbose "Check visibility of desktop number $([VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::FromIndex($TempIndex)))) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
					return ([VirtualDesktop.Desktop]::FromIndex($TempIndex)).IsVisible
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}
		return $FALSE
	}
}


function Get-LeftDesktop
{
<#
.SYNOPSIS
Get the desktop object on the "left" side
.DESCRIPTION
Get the desktop object on the "left" side
If there is no desktop on the "left" side $NULL is returned.
Returns desktop "left" to current desktop if parameter desktop is omitted.
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
Desktop object
.EXAMPLE
Get-CurrentDesktop | Get-LeftDesktop | Switch-Desktop

Switch to the desktop left of the displayed virtual desktop
.EXAMPLE
Get-LeftDesktop 1

Get desktop left to second desktop
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Returning desktop left of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		return $Desktop.Left
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				Write-Verbose "Returning desktop left of desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				return $TempDesktop.Left
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					Write-Verbose "Returning desktop left of desktop number $([VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::FromIndex($TempIndex)))) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
					return ([VirtualDesktop.Desktop]::FromIndex($TempIndex)).Left
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}

		return $NULL
	}
}


function Get-RightDesktop
{
<#
.SYNOPSIS
Get the desktop object on the "right" side
.DESCRIPTION
Get the desktop object on the "right" side
If there is no desktop on the "right" side $NULL is returned.
Returns desktop "right" to current desktop if parameter desktop is omitted.
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
Desktop object
.EXAMPLE
Get-CurrentDesktop | Get-RightDesktop | Switch-Desktop

Switch to the desktop right of the displayed virtual desktop
.EXAMPLE
Get-RightDesktop 1

Get desktop right to second desktop
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Returning desktop right of desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		return $Desktop.Right
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				Write-Verbose "Returning desktop right of desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				return $TempDesktop.Right
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					Write-Verbose "Returning desktop right of desktop number $([VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::FromIndex($TempIndex)))) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::FromIndex($TempIndex)))')"
					return ([VirtualDesktop.Desktop]::FromIndex($TempIndex)).Right
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}

		return $NULL
	}
}


if ($OSBuild -ge 22000)
{
	function Move-Desktop
	{
	<#
	.SYNOPSIS
	Move current desktop to other virtual desktop
	.DESCRIPTION
	Move current desktop to other virtual desktop.
	.PARAMETER Desktop
	Desktop object to move current desktop to
	.INPUTS
	None
	.OUTPUTS
	Desktop object
	.EXAMPLE
	Move-Window -Desktop (Get-Desktop "Other Desktop")

	Move current virtual desktop to desktop "Other Desktop"
	.EXAMPLE
	Move-Window -Desktop (Get-RightDesktop)

	Move current virtual desktop to the "right"
	.LINK
	https://github.com/MScholtes/PSVirtualDesktop
	.LINK
	https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
	.NOTES
	Author: Markus Scholtes
	Created: 2021/10/17
	#>
		[Cmdletbinding()]
		Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

		if ($NULL -eq $Desktop)
		{
			Write-Error "Parameter -Desktop missing"
			return $NULL
		}

		if ($Desktop -is [VirtualDesktop.Desktop])
		{
			Write-Verbose "Moving current desktop to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
			([VirtualDesktop.Desktop]::Current).Move([VirtualDesktop.Desktop]::FromDesktop($Desktop))
			return ([VirtualDesktop.Desktop]::Current)
		}

		Write-Error "Parameter -Desktop has to be a desktop object"
		return $NULL
	}
}

function Move-Window
{
<#
.SYNOPSIS
Move window to virtual desktop
.DESCRIPTION
Move window whose window handle is given to virtual desktop.
The parameter values are auto detected and can change places. The desktop object is handed to the output pipeline for further use.
If parameter desktop is omitted, the current desktop is used.
.PARAMETER Desktop
Desktop object
.PARAMETER Hwnd
Window handle
.INPUTS
Desktop object
.OUTPUTS
Desktop object
.EXAMPLE
Move-Window -Desktop (Get-CurrentDesktop) -Hwnd ((Get-Process "notepad")[0].MainWindowHandle)

Move notepad window to current virtual desktop
.EXAMPLE
New-Desktop | Move-Window (Get-ConsoleHandle) | Switch-Desktop

Create virtual desktop and move powershell console window to it, then activate new desktop.
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $FALSE)] $Desktop, [Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}
	else
	{
		if ($NULL -eq $Hwnd)
		{
			$Hwnd = [VirtualDesktop.Desktop]::Current
		}
	}

	if (($Hwnd -is [IntPtr]) -And ($Desktop -is [VirtualDesktop.Desktop]))
	{
		Write-Verbose "Moving window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		$Desktop.MoveWindow($Hwnd)
		return $Desktop
	}

	if (($Hwnd -is [ValueType]) -And ($Desktop -is [VirtualDesktop.Desktop]))
	{
		Write-Verbose "Moving window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		$Desktop.MoveWindow([IntPtr]$Hwnd)
		return $Desktop
	}

	if (($Desktop -is [IntPtr]) -And ($Hwnd -is [VirtualDesktop.Desktop]))
	{
		Write-Verbose "Moving window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Hwnd)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Hwnd))')"
		$Hwnd.MoveWindow($Desktop)
		return $Hwnd
	}

	if (($Desktop -is [ValueType]) -And ($Hwnd -is [VirtualDesktop.Desktop]))
	{
		Write-Verbose "Moving window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Hwnd)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Hwnd))')"
		$Hwnd.MoveWindow([IntPtr]$Desktop)
		return $Hwnd
	}

	Write-Error "Parameters -Desktop and -Hwnd have to be a desktop object and an IntPtr/integer pair"
	return $NULL
}


function Move-ActiveWindow
{
<#
.SYNOPSIS
Move active window to virtual desktop
.DESCRIPTION
Move active window to virtual desktop. The desktop object is handed to the output pipeline for further use.
If parameter desktop is omitted, the current desktop is used.
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.INPUTS
Number of desktop (starting with 0 to count-1), desktop object or string (part of desktop name)
.OUTPUTS
Desktop object
.EXAMPLE
Move-ActiveWindow -Desktop (Get-CurrentDesktop)

Move active window to current virtual desktop
.EXAMPLE
New-Desktop | Move-ActiveWindow | Switch-Desktop

Create virtual desktop and move activate window to it, then activate new desktop.
.EXAMPLE
Move-ActiveWindow "Desktop 2"

Move activate window to second desktop
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2019/02/13
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		Write-Verbose "Moving active window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
		$Desktop.MoveWindow((Get-ActiveWindowHandle))
		return $Desktop
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{
				Write-Verbose "Moving active window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
				$TempDesktop.MoveWindow((Get-ActiveWindowHandle))
				return $TempDesktop
			}
		}
		else
		{
			if ($Desktop -is [STRING])
			{
				$TempIndex = [VirtualDesktop.Desktop]::SearchDesktop($Desktop)
				if ($TempIndex -ge 0)
				{
					$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($TempIndex)
					Write-Verbose "Moving active window to desktop number $([VirtualDesktop.Desktop]::FromDesktop($TempDesktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($TempDesktop))')"
					$TempDesktop.MoveWindow((Get-ActiveWindowHandle))
					return $TempDesktop
				}
				else
				{
					Write-Error "No desktop with name part '$Desktop' found"
				}
			}
			else
			{
				Write-Error "Parameter -Desktop has to be a desktop object, an integer or a string"
			}
		}

	return $NULL
	}
}


function Test-Window
{
<#
.SYNOPSIS
Check if window is displayed on virtual desktop
.DESCRIPTION
Check if window  whose window handle is given is displayed on virtual desktop.
The parameter values are auto detected and can change places. If parameter desktop is not supplied, the current desktop is used.
.PARAMETER Desktop
Desktop object. If omitted the current desktop is used.
.PARAMETER Hwnd
Window handle
.INPUTS
Desktop object
.OUTPUTS
Boolean
.EXAMPLE
Test-Window -Hwnd ((Get-Process "notepad")[0].MainWindowHandle)

Check if notepad window is displayed on current virtual desktop
.EXAMPLE
Get-Desktop 1 | Test-Window (Get-ConsoleHandle)

Check if powershell console window is displayed on virtual desktop with number 1 (second desktop)
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $FALSE)] $Desktop, [Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		if ($Desktop -is [VirtualDesktop.Desktop])
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
			return $Desktop.HasWindow($Hwnd)
		}
		else
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop([VirtualDesktop.Desktop]::Current)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::Current))')"
			return ([VirtualDesktop.Desktop]::Current).HasWindow($Hwnd)
		}
	}

	if ($Hwnd -is [ValueType])
	{
		if ($Desktop -is [VirtualDesktop.Desktop])
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop($Desktop)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Desktop))')"
			return $Desktop.HasWindow([IntPtr]$Hwnd)
		}
		else
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop([VirtualDesktop.Desktop]::Current)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::Current))')"
			return ([VirtualDesktop.Desktop]::Current).HasWindow([IntPtr]$Hwnd)
		}
	}

	if ($Desktop -is [IntPtr])
	{
		if ($Hwnd -is [VirtualDesktop.Desktop])
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop($Hwnd)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Hwnd))')"
			return $Hwnd.HasWindow($Desktop)
		}
		else
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop([VirtualDesktop.Desktop]::Current)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::Current))')"
			return ([VirtualDesktop.Desktop]::Current).HasWindow($Desktop)
		}
	}

	if ($Desktop -is [ValueType])
	{
		if ($Hwnd -is [VirtualDesktop.Desktop])
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop($Hwnd)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop($Hwnd))')"
			return $Hwnd.HasWindow([IntPtr]$Desktop)
		}
		else
		{
			Write-Verbose "Checking window on desktop number $([VirtualDesktop.Desktop]::FromDesktop([VirtualDesktop.Desktop]::Current)) ('$([VirtualDesktop.Desktop]::DesktopNameFromDesktop([VirtualDesktop.Desktop]::Current))')"
			return ([VirtualDesktop.Desktop]::Current).HasWindow([IntPtr]$Desktop)
		}
	}

	Write-Error "Parameters -Desktop and -Hwnd have to be a desktop object and an IntPtr/integer pair"
	return $FALSE
}


function Pin-Window
{
<#
.SYNOPSIS
Pin window to all desktops
.DESCRIPTION
Pin window whose window handle is given to all desktops.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
None
.EXAMPLE
Pin-Window ((Get-Process "notepad")[0].MainWindowHandle)

Pin notepad window to all desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::PinWindow($Hwnd)
		Write-Verbose "Pinned window with handle $Hwnd to all desktops"
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::PinWindow([IntPtr]$Hwnd)
			Write-Verbose "Pinned window with handle $Hwnd to all desktops"
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
		}
	}
}


function Unpin-Window
{
<#
.SYNOPSIS
Unpin window from all desktops
.DESCRIPTION
Unpin window whose window handle is given from all desktops.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
None
.EXAMPLE
Unpin-Window ((Get-Process "notepad")[0].MainWindowHandle)

Unpin notepad window from all desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::UnpinWindow($Hwnd)
		Write-Verbose "Unpinned window with handle $Hwnd from all desktops"
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::UnpinWindow([IntPtr]$Hwnd)
			Write-Verbose "Unpinned window with handle $Hwnd from all desktops"
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
		}
	}
}


function Test-WindowPinned
{
<#
.SYNOPSIS
Checks whether a window is pinned to all desktops
.DESCRIPTION
Checks whether a window whose window handle is given is pinned to all desktops.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
Boolean
.EXAMPLE
Test-WindowPinned ((Get-Process "notepad")[0].MainWindowHandle)

Checks whether notepad window is pinned to all virtual desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		Write-Verbose "Check if window with handle $Hwnd is pinned to all desktops"
		return [VirtualDesktop.Desktop]::IsWindowPinned($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			Write-Verbose "Check if window with handle $Hwnd is pinned to all desktops"
			return [VirtualDesktop.Desktop]::IsWindowPinned([IntPtr]$Hwnd)
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
			return $FALSE
		}
	}
}


function Pin-Application
{
<#
.SYNOPSIS
Pin application to all desktops
.DESCRIPTION
Pin application whose window handle is given to all desktops.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
None
.EXAMPLE
Pin-Application ((Get-Process "notepad")[0].MainWindowHandle)

Pin all notepad windows to all desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::PinApplication($Hwnd)
		Write-Verbose "Pinned application with window handle $Hwnd to all desktops"
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::PinApplication([IntPtr]$Hwnd)
			Write-Verbose "Pinned application with window handle $Hwnd to all desktops"
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
		}
	}
}


function Unpin-Application
{
<#
.SYNOPSIS
Unpin application from all desktops
.DESCRIPTION
Unpin application whose window handle is given from all desktops.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
None
.EXAMPLE
Unpin-Application ((Get-Process "notepad")[0].MainWindowHandle)

Unpin all notepad windows from all desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::UnpinApplication($Hwnd)
		Write-Verbose "Unpinned application with window handle $Hwnd from all desktops"
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::UnpinApplication([IntPtr]$Hwnd)
			Write-Verbose "Unpinned application with window handle $Hwnd from all desktops"
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
		}
	}
}


function Test-ApplicationPinned
{
<#
.SYNOPSIS
Checks whether an application is pinned to all desktops
.DESCRIPTION
Checks whether an application whose window handle is given is pinned to all desktops.
.PARAMETER Hwnd
Window handle
.INPUTS
IntPtr
.OUTPUTS
Boolean
.EXAMPLE
Test-ApplicationPinned ((Get-Process "notepad")[0].MainWindowHandle)

Checks whether notepad windows are pinned to all virtual desktops
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
Updated: 2020/06/27
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		Write-Verbose "Check if application with window handle $Hwnd is pinned to all desktops"
		return [VirtualDesktop.Desktop]::IsApplicationPinned($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			Write-Verbose "Check if application with window handle $Hwnd is pinned to all desktops"
			return [VirtualDesktop.Desktop]::IsApplicationPinned([IntPtr]$Hwnd)
		}
		else
		{
			Write-Error "Parameter -Hwnd has to be an IntPtr or an integer"
			return $FALSE
		}
	}
}


function Get-ConsoleHandle
{
<#
.SYNOPSIS
Get window handle of powershell console
.DESCRIPTION
Get window handle of powershell console in a safe way (means: if powershell is started in a cmd window, the cmd window handled is returned).
.INPUTS
None
.OUTPUTS
IntPtr
.EXAMPLE
Get-ConsoleHandle

Get window handle of powershell console
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2018/10/22
Updated: 2022/02/25
#>
	[Cmdletbinding()]
	Param()

	Write-Verbose "Retrieving console window handle"
	if ($NULL -ne $ENV:wt_session)
	{ # seems to be running in Windows Terminal
		$HANDLE = (Get-Process -PID ((Get-WmiObject -Class win32_process -Filter "processid='$PID'").ParentProcessId)).MainWindowHandle
	}
	else
	{ # Powershell in own console
		$HANDLE = [VirtualDesktop.Desktop]::GetConsoleWindow()
		if ($HANDLE -eq 0)
		{ # maybe script is started in ISE
			$HANDLE = (Get-Process -PID $PID).MainWindowHandle
		}
	}
	return $HANDLE
}


function Get-ActiveWindowHandle
{
<#
.SYNOPSIS
Get window handle of foreground window
.DESCRIPTION
Get window handle of foreground window (the foreground window is always on the current virtual desktop).
.INPUTS
None
.OUTPUTS
IntPtr
.EXAMPLE
Get-ActiveWindowHandle

Get window handle of foreground window
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2019/02/13
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param()

	Write-Verbose "Retrieving handle of active window"
	return [VirtualDesktop.Desktop]::GetForegroundWindow()
}

function Find-WindowHandle
{
<#
.SYNOPSIS
Find window handle to title text or retrieve list of windows with title
.DESCRIPTION
Find first window handle to partial title text (not case sensitive) or retrieve list of windows with title if *
is supplied as title
.PARAMETER Title
Partial window title or *. The search is not case sensitive.
.INPUTS
STRING
.OUTPUTS
Int or Array of WindowInformation
.EXAMPLE
Find-WindowHandle powershell

Get window handle of first powershell window
.EXAMPLE
Find-WindowHandle *

Get a list of all windows with title
.EXAMPLE
Find-WindowHandle * | ? { $_.Title -match "firefox" }

Find all windows that contain the text "firefox" in their title
.LINK
https://github.com/MScholtes/PSVirtualDesktop
.LINK
https://github.com/MScholtes/TechNet-Gallery/tree/master/VirtualDesktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2019/09/04
Updated: 2020/06/27
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Title)

	if ($Title -eq "*")
	{
		Write-Verbose "Retrieving window titles and handles of all windows with titles"
		return [VirtualDesktop.Desktop]::GetWindows()
	}
	else
	{
		Write-Verbose "Retrieving window handles of first window with '$Title' in title"
		$RESULT = [VirtualDesktop.Desktop]::FindWindow($Title)
		if ($RESULT)
		{
			Write-Verbose "Window '$($RESULT.Title)' found"
			return $RESULT.Handle
		}
		else
		{
			Write-Verbose "No window found"
			return 0
		}
	}
}

# Clean up variables
Remove-Variable -Name OSVer,OSBuild
