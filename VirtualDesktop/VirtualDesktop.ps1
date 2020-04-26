# Author: Markus Scholtes, 2017/05/08
# Version 2.4 - new function Find-WindowHandle, 2019/09/04

# prefer $PSVersionTable.BuildVersion to [Environment]::OSVersion.Version
# since a wrong Windows version might be returned in RunSpaces
if ($PSVersionTable.PSVersion.Major -lt 6)
{ # Powershell 5.x
	$OSVer = $PSVersionTable.BuildVersion.Major
	$OSBuild = $PSVersionTable.BuildVersion.Build
}
else
{ # Powershell 6.x
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

$Windows1607 = $TRUE
$Windows1803 = $FALSE
$Windows1809 = $FALSE
if ($OSBuild -ge 17134)
{
	$Windows1607 = $FALSE
	$Windows1803 = $TRUE
	$Windows1809 = $FALSE
}
if ($OSBuild -ge 17661)
{
	$Windows1607 = $FALSE
	$Windows1803 = $FALSE
	$Windows1809 = $TRUE
}

Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.ComponentModel;

// Based on http://stackoverflow.com/a/32417530, Windows 10 SDK and github projects Grabacr07/VirtualDesktop and mzomparelli/zVirtualDesktop

namespace VirtualDesktop
{
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
// https://github.com/mzomparelli/zVirtualDesktop/wiki: Updated interfaces in Windows 10 build 17134, 17661, and 17666
$(if ($Windows1607) {@"
// Windows 10 1607 and Server 2016:
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("9AC0B5C8-1484-4C5B-9533-4134A0F97CEA")]
"@ })
$(if ($Windows1803) {@"
// Windows 10 1803:
	[InterfaceType(ComInterfaceType.InterfaceIsIInspectable)]
	[Guid("871F602A-2B58-42B4-8C4B-6C43D642C06F")]
"@ })
$(if ($Windows1809) {@"
// Windows 10 1809:
	[InterfaceType(ComInterfaceType.InterfaceIsIInspectable)]
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
$(if ($Windows1607) {@"
		int GetPositionPriority(out IntPtr /* IShellPositionerPriority** */ priority);
		int SetPositionPriority(IntPtr /* IShellPositionerPriority* */ priority);
"@ })
		int GetSizeConstraints(IntPtr /* IImmersiveMonitor* */ monitor, out Size size1, out Size size2);
		int GetSizeConstraintsForDpi(uint uint1, out Size size1, out Size size2);
		int SetSizeConstraintsForDpi(ref uint uint1, ref Size size1, ref Size size2);
$(if ($Windows1607) {@"
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
$(if ($Windows1803) {@"
		int Unknown1(out int unknown);
		int Unknown2(out int unknown);
		int Unknown3(out int unknown);
		int Unknown4(out int unknown);
"@ })
$(if ($Windows1809) {@"
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
$(if ($Windows1607) {@"
// Windows 10 1607 and Server 2016:
	[Guid("2C08ADF0-A386-4B35-9250-0FE183476FCC")]
"@ })
$(if ($Windows1803) {@"
// Windows 10 1803:
	[Guid("2C08ADF0-A386-4B35-9250-0FE183476FCC")]
"@ })
$(if ($Windows1809) {@"
// Windows 10 1809:
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
$(if ($Windows1803 -or $Windows1809) {@"
// Windows 10 1803 and 1809:
		int Unknown1(out IntPtr view);
"@ })
		void RefreshCollection();
		int RegisterForApplicationViewChanges(object listener, out int cookie);
$(if ($Windows1607) {@"
// Windows 10 1607 and Server 2016:
		int RegisterForApplicationViewPositionChanges(object listener, out int cookie);
"@ })
$(if ($Windows1803) {@"
// Windows 10 1803:
		int RegisterForApplicationViewPositionChanges(object listener, out int cookie);
"@ })
		int UnregisterForApplicationViewChanges(int cookie);
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	[Guid("FF72FFDD-BE7E-43FC-9C03-AD81681E88E4")]
	internal interface IVirtualDesktop
	{
		bool IsViewVisible(IApplicationView view);
		Guid GetId();
	}

	[ComImport]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
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

	internal static class DesktopManager
	{
		static DesktopManager()
		{
			var shell = (IServiceProvider10)Activator.CreateInstance(Type.GetTypeFromCLSID(Guids.CLSID_ImmersiveShell));
			VirtualDesktopManagerInternal = (IVirtualDesktopManagerInternal)shell.QueryService(Guids.CLSID_VirtualDesktopManagerInternal, typeof(IVirtualDesktopManagerInternal).GUID);
			VirtualDesktopManager = (IVirtualDesktopManager)Activator.CreateInstance(Type.GetTypeFromCLSID(Guids.CLSID_VirtualDesktopManager));
			ApplicationViewCollection = (IApplicationViewCollection)shell.QueryService(typeof(IApplicationViewCollection).GUID, typeof(IApplicationViewCollection).GUID);
			VirtualDesktopPinnedApps = (IVirtualDesktopPinnedApps)shell.QueryService(Guids.CLSID_VirtualDesktopPinnedApps, typeof(IVirtualDesktopPinnedApps).GUID);
		}

		internal static IVirtualDesktopManagerInternal VirtualDesktopManagerInternal;
		internal static IVirtualDesktopManager VirtualDesktopManager;
		internal static IApplicationViewCollection ApplicationViewCollection;
		internal static IVirtualDesktopPinnedApps VirtualDesktopPinnedApps;

		internal static IVirtualDesktop GetDesktop(int index)
		{	// get desktop with index
			int count = VirtualDesktopManagerInternal.GetCount();
			if (index < 0 || index >= count) throw new ArgumentOutOfRangeException("index");
			IObjectArray desktops;
			VirtualDesktopManagerInternal.GetDesktops(out desktops);
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
			VirtualDesktopManagerInternal.GetDesktops(out desktops);
			object objdesktop;
			for (int i = 0; i < VirtualDesktopManagerInternal.GetCount(); i++)
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

	public class WindowInformation
	{ // stores window informations
		public string Title { get; set; }
		public int Handle { get; set; }
	}

	public class Desktop
	{
		private IVirtualDesktop ivd;
		private Desktop(IVirtualDesktop desktop) { this.ivd = desktop; }

		public override int GetHashCode()
		{ // Get hash
			return ivd.GetHashCode();
		}

		public override bool Equals(object obj)
		{ // Compares with object
			var desk = obj as Desktop;
			return desk != null && object.ReferenceEquals(this.ivd, desk.ivd);
		}

		public static int Count
		{ // Returns the number of desktops
			get { return DesktopManager.VirtualDesktopManagerInternal.GetCount(); }
		}

		public static Desktop Current
		{ // Returns current desktop
			get { return new Desktop(DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop()); }
		}

		public static Desktop FromIndex(int index)
		{ // Create desktop object from index 0..Count-1
			return new Desktop(DesktopManager.GetDesktop(index));
		}

		public static Desktop FromWindow(IntPtr hWnd)
		{ // Creates desktop object on which window <hWnd> is displayed
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			Guid id = DesktopManager.VirtualDesktopManager.GetWindowDesktopId(hWnd);
			return new Desktop(DesktopManager.VirtualDesktopManagerInternal.FindDesktop(ref id));
		}

		public static int FromDesktop(Desktop desktop)
		{ // Returns index of desktop object or -1 if not found
			return DesktopManager.GetDesktopIndex(desktop.ivd);
		}

		public static Desktop Create()
		{ // Create a new desktop
			return new Desktop(DesktopManager.VirtualDesktopManagerInternal.CreateDesktop());
		}

		public void Remove(Desktop fallback = null)
		{ // Destroy desktop and switch to <fallback>
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

		public bool IsVisible
		{ // Returns <true> if this desktop is the current displayed one
			get { return object.ReferenceEquals(ivd, DesktopManager.VirtualDesktopManagerInternal.GetCurrentDesktop()); }
		}

		public void MakeVisible()
		{ // Make this desktop visible
			DesktopManager.VirtualDesktopManagerInternal.SwitchDesktop(ivd);
		}

		public Desktop Left
		{ // Returns desktop at the left of this one, null if none
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
		{ // Returns desktop at the right of this one, null if none
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
		{ // Move window <hWnd> to this desktop
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
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
				DesktopManager.VirtualDesktopManagerInternal.MoveViewToDesktop(view, ivd);
			}
		}

		public bool HasWindow(IntPtr hWnd)
		{ // Returns true if window <hWnd> is on this desktop
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			return ivd.GetId() == DesktopManager.VirtualDesktopManager.GetWindowDesktopId(hWnd);
		}

		public static bool IsWindowPinned(IntPtr hWnd)
		{ // Returns true if window <hWnd> is pinned to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			return DesktopManager.VirtualDesktopPinnedApps.IsViewPinned(hWnd.GetApplicationView());
		}

		public static void PinWindow(IntPtr hWnd)
		{ // pin window <hWnd> to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			var view = hWnd.GetApplicationView();
			if (!DesktopManager.VirtualDesktopPinnedApps.IsViewPinned(view))
			{ // pin only if not already pinned
				DesktopManager.VirtualDesktopPinnedApps.PinView(view);
			}
		}

		public static void UnpinWindow(IntPtr hWnd)
		{ // unpin window <hWnd> from all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			var view = hWnd.GetApplicationView();
			if (DesktopManager.VirtualDesktopPinnedApps.IsViewPinned(view))
			{ // unpin only if not already unpinned
				DesktopManager.VirtualDesktopPinnedApps.UnpinView(view);
			}
		}

		public static bool IsApplicationPinned(IntPtr hWnd)
		{ // Returns true if application for window <hWnd> is pinned to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			return DesktopManager.VirtualDesktopPinnedApps.IsAppIdPinned(DesktopManager.GetAppId(hWnd));
		}

		public static void PinApplication(IntPtr hWnd)
		{ // pin application for window <hWnd> to all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			string appId = DesktopManager.GetAppId(hWnd);
			if (!DesktopManager.VirtualDesktopPinnedApps.IsAppIdPinned(appId))
			{ // pin only if not already pinned
				DesktopManager.VirtualDesktopPinnedApps.PinAppID(appId);
			}
		}

		public static void UnpinApplication(IntPtr hWnd)
		{ // unpin application for window <hWnd> from all desktops
			if (hWnd == IntPtr.Zero) throw new ArgumentNullException();
			var view = hWnd.GetApplicationView();
			string appId = DesktopManager.GetAppId(hWnd);
			if (DesktopManager.VirtualDesktopPinnedApps.IsAppIdPinned(appId))
			{ // unpin only if already pinned
				DesktopManager.VirtualDesktopPinnedApps.UnpinAppID(appId);
			}
		}

		// get window handle of current console window (even if powershell started in cmd)
		[DllImport("Kernel32.dll")]
		public static extern IntPtr GetConsoleWindow();

		// get handle of active window
		[DllImport("user32.dll")]
		public static extern IntPtr GetForegroundWindow();

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
}
"@

# Clean up variables
Remove-Variable -Name Windows1607,Windows1803,Windows1809,OSVer,OSBuild


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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	return [VirtualDesktop.Desktop]::Count
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	return [VirtualDesktop.Desktop]::Create()
}


function Switch-Desktop
{
<#
.SYNOPSIS
Switch to virtual desktop
.DESCRIPTION
Switch to virtual desktop
.PARAMETER Desktop
Number of desktop (starting with 0 to count-1) or desktop object
.INPUTS
Number of desktop (starting with 0 to count-1) or desktop object
.OUTPUTS
None
.EXAMPLE
Switch-Desktop 0

Switch to first virtual desktop
.EXAMPLE
Switch-Desktop $Desktop

Switch to virtual desktop $Desktop
.EXAMPLE
New-Desktop | Switch-Desktop

Create virtual desktop and switch to it
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		$Desktop.MakeVisible()
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{ $TempDesktop.MakeVisible() }
		}
		else
		{
			Write-Error "Parameter -Desktop has to be a Desktop object or an integer"
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
Number of desktop (starting with 0 to count-1) or desktop object
.INPUTS
Number of desktop (starting with 0 to count-1) or desktop object
.OUTPUTS
None
.EXAMPLE
Remove-Desktop 0

Remove first virtual desktop
.EXAMPLE
Remove-Desktop $Desktop

Remove virtual desktop $Desktop
.EXAMPLE
New-Desktop | Remove-Desktop

Create virtual desktop and remove it immediately
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::FromIndex(([VirtualDesktop.Desktop]::Count) -1)
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		$Desktop.Remove()
	}
	else
	{
		if ($Desktop -is [ValueType])
		{
			$TempDesktop = [VirtualDesktop.Desktop]::FromIndex($Desktop)
			if ($TempDesktop)
			{ $TempDesktop.Remove() }
		}
		else
		{
			Write-Error "Parameter -Desktop has to be a Desktop object or an integer"
		}
	}
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	return [VirtualDesktop.Desktop]::Current
}


function Get-Desktop
{
<#
.SYNOPSIS
Get virtual desktop with index number (0 to count-1)
.DESCRIPTION
Get virtual desktop with index number (0 to count-1)
Returns $NULL if index number is out of range.
Returns current desktop is index is omitted.
.PARAMETER Index
Number of desktop (starting with 0 to count-1)
.INPUTS
Int32
.OUTPUTS
Desktop object
.EXAMPLE
Get-Desktop 1 | Switch-Desktop

Get object of second virtual desktop and switch to it
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([VirtualDesktop.Desktop])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Index)

	if ($NULL -eq $Index)
	{
		return [VirtualDesktop.Desktop]::Current
	}

	if ($Index -is [ValueType])
	{
		return [VirtualDesktop.Desktop]::FromIndex($Index)
	}
	else
	{
		Write-Error "Parameter -Index has to be an integer"
		return $NULL
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
Desktop object
.INPUTS
Desktop object
.OUTPUTS
Int32
.EXAMPLE
New-Desktop | Get-DesktopIndex

Get index number of new virtual desktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([INT32])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		return [VirtualDesktop.Desktop]::FromDesktop(([VirtualDesktop.Desktop]::Current))
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		return [VirtualDesktop.Desktop]::FromDesktop($Desktop)
	}
	else
	{
		Write-Error "Parameter -Desktop has to be a Desktop object"
		return -1
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
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([VirtualDesktop.Desktop])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		return [VirtualDesktop.Desktop]::FromWindow($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			return [VirtualDesktop.Desktop]::FromWindow([IntPtr]$Hwnd)
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
Desktop object
.INPUTS
Desktop object
.OUTPUTS
Boolean
.EXAMPLE
Get-DesktopIndex 1 | Test-CurrentDesktop

Checks whether the desktop with count number 1 is the displayed virtual desktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		return $Desktop.IsVisible
	}
	else
	{
		Write-Error "Parameter -Desktop has to be a Desktop object"
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
Desktop object
.INPUTS
Desktop object
.OUTPUTS
Desktop object
.EXAMPLE
Get-CurrentDesktop | Get-LeftDesktop | Switch-Desktop

Switch to the desktop left to the displayed virtual desktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		return ([VirtualDesktop.Desktop]::Current).Left
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		return $Desktop.Left
	}
	else
	{
		Write-Error "Parameter -Desktop has to be a Desktop object"
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
Desktop object
.INPUTS
Desktop object
.OUTPUTS
Desktop object
.EXAMPLE
Get-CurrentDesktop | Get-RightDesktop | Switch-Desktop

Switch to the desktop right to the displayed virtual desktop
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		return ([VirtualDesktop.Desktop]::Current).Right
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		return $Desktop.Right
	}
	else
	{
		Write-Error "Parameter -Desktop has to be a Desktop object"
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
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
		$Desktop.MoveWindow($Hwnd)
		return $Desktop
	}

	if (($Hwnd -is [ValueType]) -And ($Desktop -is [VirtualDesktop.Desktop]))
	{
		$Desktop.MoveWindow([IntPtr]$Hwnd)
		return $Desktop
	}

	if (($Desktop -is [IntPtr]) -And ($Hwnd -is [VirtualDesktop.Desktop]))
	{
		$Hwnd.MoveWindow($Desktop)
		return $Hwnd
	}

	if (($Desktop -is [ValueType]) -And ($Hwnd -is [VirtualDesktop.Desktop]))
	{
		$Hwnd.MoveWindow([IntPtr]$Desktop)
		return $Hwnd
	}

	Write-Error "Parameters -Desktop and -Hwnd have to be a Desktop object and an IntPtr/integer pair"
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
Desktop object
.INPUTS
Desktop object
.OUTPUTS
Desktop object
.EXAMPLE
Move-ActiveWindow -Desktop (Get-CurrentDesktop)

Move active window to current virtual desktop
.EXAMPLE
New-Desktop | Move-ActiveWindow | Switch-Desktop

Create virtual desktop and move activate console window to it, then activate new desktop.
.LINK
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2019/02/13
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Desktop)

	if ($NULL -eq $Desktop)
	{
		$Desktop = [VirtualDesktop.Desktop]::Current
	}

	if ($Desktop -is [VirtualDesktop.Desktop])
	{
		$Desktop.MoveWindow((Get-ActiveWindowHandle))
		return $Desktop
	}

	Write-Error "Parameter -Desktop has to be a Desktop object"
	return $NULL
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $FALSE)] $Desktop, [Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		if ($Desktop -is [VirtualDesktop.Desktop])
		{
			return $Desktop.HasWindow($Hwnd)
		}
		else
		{
			return ([VirtualDesktop.Desktop]::Current).HasWindow($Hwnd)
		}
	}

	if ($Hwnd -is [ValueType])
	{
		if ($Desktop -is [VirtualDesktop.Desktop])
		{
			return $Desktop.HasWindow([IntPtr]$Hwnd)
		}
		else
		{
			return ([VirtualDesktop.Desktop]::Current).HasWindow([IntPtr]$Hwnd)
		}
	}

	if ($Desktop -is [IntPtr])
	{
		if ($Hwnd -is [VirtualDesktop.Desktop])
		{
			return $Hwnd.HasWindow($Desktop)
		}
		else
		{
			return ([VirtualDesktop.Desktop]::Current).HasWindow($Desktop)
		}
	}

	if ($Desktop -is [ValueType])
	{
		if ($Hwnd -is [VirtualDesktop.Desktop])
		{
			return $Hwnd.HasWindow([IntPtr]$Desktop)
		}
		else
		{
			return ([VirtualDesktop.Desktop]::Current).HasWindow([IntPtr]$Desktop)
		}
	}

	Write-Error "Parameters -Desktop and -Hwnd have to be a Desktop object and an IntPtr/integer pair"
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::PinWindow($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::PinWindow([IntPtr]$Hwnd)
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::UnpinWindow($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::UnpinWindow([IntPtr]$Hwnd)
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		return [VirtualDesktop.Desktop]::IsWindowPinned($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::PinApplication($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::PinApplication([IntPtr]$Hwnd)
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		[VirtualDesktop.Desktop]::UnpinApplication($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
			[VirtualDesktop.Desktop]::UnpinApplication([IntPtr]$Hwnd)
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2017/05/08
#>
	[OutputType([BOOLEAN])]
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Hwnd)

	if ($Hwnd -is [IntPtr])
	{
		return [VirtualDesktop.Desktop]::IsApplicationPinned($Hwnd)
	}
	else
	{
		if ($Hwnd -is [ValueType])
		{
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2018/10/22
#>
	if ([VirtualDesktop.Desktop]::GetConsoleWindow() -ne 0)
	{ return [VirtualDesktop.Desktop]::GetConsoleWindow() }
	else # maybe script is started in ISE
	{ return (Get-Process -PID $PID).MainWindowHandle }
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2019/02/13
#>
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
https://gallery.technet.microsoft.com/scriptcenter/Powershell-commands-to-d0e79cc5
.NOTES
Author: Markus Scholtes
Created: 2019/09/04
#>
	[Cmdletbinding()]
	Param([Parameter(ValueFromPipeline = $TRUE)] $Title)

	if ($Title -eq "*")
	{
		return [VirtualDesktop.Desktop]::GetWindows()
	}
	else
	{
		$RESULT = [VirtualDesktop.Desktop]::FindWindow($Title)
		if ($RESULT)
		{
			return $RESULT.Handle
		}
		else
		{
			return 0
		}
	}
}
